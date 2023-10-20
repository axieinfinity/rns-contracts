// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { INSUnified, INSAuction } from "./interfaces/INSAuction.sol";
import { LibSafeRange } from "./libraries/math/LibSafeRange.sol";
import { LibRNSDomain } from "./libraries/LibRNSDomain.sol";
import { LibEventRange, EventRange } from "./libraries/LibEventRange.sol";
import { RONTransferHelper } from "./libraries/transfers/RONTransferHelper.sol";

contract RNSAuction is Initializable, AccessControlEnumerable, INSAuction {
  using LibSafeRange for uint256;
  using BitMaps for BitMaps.BitMap;
  using LibEventRange for EventRange;

  /// @inheritdoc INSAuction
  uint64 public constant MAX_EXPIRY = type(uint64).max;
  /// @inheritdoc INSAuction
  uint256 public constant MAX_PERCENTAGE = 100_00;
  /// @inheritdoc INSAuction
  uint64 public constant DOMAIN_EXPIRY_DURATION = 365 days;
  /// @inheritdoc INSAuction
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev The RNSUnified contract.
  INSUnified internal _rnsUnified;
  /// @dev Mapping from auction Id => event range
  mapping(bytes32 auctionId => EventRange) internal _auctionRange;
  /// @dev Mapping from id of domain names => auction detail.
  mapping(uint256 id => DomainAuction) internal _domainAuction;

  /// @dev The treasury.
  address payable internal _treasury;
  /// @dev The gap ratio between 2 bids with the starting price.
  uint256 internal _bidGapRatio;
  /// @dev Mapping from id => bool reserved status
  BitMaps.BitMap internal _reserved;

  modifier whenNotStarted(bytes32 auctionId) {
    _requireNotStarted(auctionId);
    _;
  }

  modifier onlyValidEventRange(EventRange calldata range) {
    _requireValidEventRange(range);
    _;
  }

  constructor() payable {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address[] calldata operators,
    INSUnified rnsUnified,
    address payable treasury,
    uint256 bidGapRatio
  ) external initializer {
    _setTreasury(treasury);
    _setBidGapRatio(bidGapRatio);
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    uint256 length = operators.length;
    bytes32 operatorRole = OPERATOR_ROLE;

    for (uint256 i; i < length;) {
      _setupRole(operatorRole, operators[i]);

      unchecked {
        ++i;
      }
    }

    _rnsUnified = rnsUnified;
  }

  /**
   * @inheritdoc INSAuction
   */
  function bulkRegister(string[] calldata labels) external onlyRole(OPERATOR_ROLE) returns (uint256[] memory ids) {
    uint256 length = labels.length;
    if (length == 0) revert InvalidArrayLength();
    ids = new uint256[](length);
    INSUnified rnsUnified = _rnsUnified;
    uint256 parentId = LibRNSDomain.RON_ID;
    uint64 domainExpiryDuration = DOMAIN_EXPIRY_DURATION;

    for (uint256 i; i < length;) {
      (, ids[i]) = rnsUnified.mint(parentId, labels[i], address(0x0), address(this), domainExpiryDuration);
      _reserved.set(ids[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INSAuction
   */
  function reserved(uint256 id) public view returns (bool) {
    return _reserved.get(id);
  }

  /**
   * @inheritdoc INSAuction
   */
  function createAuctionEvent(EventRange calldata range)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyValidEventRange(range)
    returns (bytes32 auctionId)
  {
    auctionId = keccak256(abi.encode(_msgSender(), range));
    _auctionRange[auctionId] = range;
    emit AuctionEventSet(auctionId, range);
  }

  /**
   * @inheritdoc INSAuction
   */
  function setAuctionEvent(bytes32 auctionId, EventRange calldata range)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyValidEventRange(range)
    whenNotStarted(auctionId)
  {
    _auctionRange[auctionId] = range;
    emit AuctionEventSet(auctionId, range);
  }

  /**
   * @inheritdoc INSAuction
   */
  function getAuctionEvent(bytes32 auctionId) public view returns (EventRange memory) {
    return _auctionRange[auctionId];
  }

  /**
   * @inheritdoc INSAuction
   */
  function listNamesForAuction(bytes32 auctionId, uint256[] calldata ids, uint256[] calldata startingPrices)
    external
    onlyRole(OPERATOR_ROLE)
    whenNotStarted(auctionId)
  {
    uint256 length = ids.length;
    if (length == 0 || length != startingPrices.length) revert InvalidArrayLength();
    uint256 id;
    bytes32 mAuctionId;
    DomainAuction storage sAuction;

    for (uint256 i; i < length;) {
      id = ids[i];
      if (!reserved(id)) revert NameNotReserved();

      sAuction = _domainAuction[id];
      mAuctionId = sAuction.auctionId;
      if (!(mAuctionId == 0 || mAuctionId == auctionId || sAuction.bid.timestamp == 0)) {
        revert AlreadyBidding();
      }

      sAuction.auctionId = auctionId;
      sAuction.startingPrice = startingPrices[i];

      unchecked {
        ++i;
      }
    }

    emit LabelsListed(auctionId, ids, startingPrices);
  }

  /**
   * @inheritdoc INSAuction
   */
  function placeBid(uint256 id) external payable {
    DomainAuction memory auction = _domainAuction[id];
    EventRange memory range = _auctionRange[auction.auctionId];
    uint256 beatPrice = _getBeatPrice(auction, range);

    if (!range.isInPeriod()) revert QueryIsNotInPeriod();
    if (msg.value < beatPrice) revert InsufficientAmount();
    address payable bidder = payable(_msgSender());
    // check whether the bidder can receive RON
    if (!RONTransferHelper.send(bidder, 0)) revert BidderCannotReceiveRON();
    address payable prvBidder = auction.bid.bidder;
    uint256 prvPrice = auction.bid.price;

    Bid storage sBid = _domainAuction[id].bid;
    sBid.price = msg.value;
    sBid.bidder = bidder;
    sBid.timestamp = block.timestamp;
    emit BidPlaced(auction.auctionId, id, msg.value, bidder, prvPrice, prvBidder);

    // refund for previous bidder
    if (prvPrice != 0) RONTransferHelper.safeTransfer(prvBidder, prvPrice);
  }

  /**
   * @inheritdoc INSAuction
   */
  function bulkClaimBidNames(uint256[] calldata ids) external returns (bool[] memory claimeds) {
    uint256 id;
    uint256 accumulatedRON;
    EventRange memory range;
    DomainAuction memory auction;
    uint256 length = ids.length;
    claimeds = new bool[](length);
    INSUnified rnsUnified = _rnsUnified;
    uint64 expiry = uint64(block.timestamp.addWithUpperbound(DOMAIN_EXPIRY_DURATION, MAX_EXPIRY));

    for (uint256 i; i < length;) {
      id = ids[i];
      auction = _domainAuction[id];
      range = _auctionRange[auction.auctionId];

      if (!auction.bid.claimed) {
        if (!range.isEnded()) revert NotYetEnded();
        if (auction.bid.timestamp == 0) revert NoOneBidded();

        accumulatedRON += auction.bid.price;
        rnsUnified.setExpiry(id, expiry);
        rnsUnified.transferFrom(address(this), auction.bid.bidder, id);

        _domainAuction[id].bid.claimed = claimeds[i] = true;
      }

      unchecked {
        ++i;
      }
    }

    RONTransferHelper.safeTransfer(_treasury, accumulatedRON);
  }

  /**
   * @inheritdoc INSAuction
   */
  function getRNSUnified() external view returns (INSUnified) {
    return _rnsUnified;
  }

  /**
   * @inheritdoc INSAuction
   */
  function getTreasury() external view returns (address) {
    return _treasury;
  }

  /**
   * @inheritdoc INSAuction
   */
  function getBidGapRatio() external view returns (uint256) {
    return _bidGapRatio;
  }

  /**
   * @inheritdoc INSAuction
   */
  function setTreasury(address payable addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTreasury(addr);
  }

  /**
   * @inheritdoc INSAuction
   */

  function setBidGapRatio(uint256 ratio) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setBidGapRatio(ratio);
  }

  /**
   * @inheritdoc INSAuction
   */
  function getAuction(uint256 id) public view returns (DomainAuction memory auction, uint256 beatPrice) {
    auction = _domainAuction[id];
    EventRange memory range = getAuctionEvent(auction.auctionId);
    beatPrice = _getBeatPrice(auction, range);
  }

  /**
   * @dev Helper method to set treasury.
   *
   * Emits an event {TreasuryUpdated}.
   */
  function _setTreasury(address payable addr) internal {
    if (addr == address(0)) revert NullAssignment();
    _treasury = addr;
    emit TreasuryUpdated(addr);
  }

  /**
   * @dev Helper method to set bid gap ratio.
   *
   * Emits an event {BidGapRatioUpdated}.
   */
  function _setBidGapRatio(uint256 ratio) internal {
    if (ratio > MAX_PERCENTAGE) revert RatioIsTooLarge();
    _bidGapRatio = ratio;
    emit BidGapRatioUpdated(ratio);
  }

  /**
   * @dev Helper method to get beat price.
   */
  function _getBeatPrice(DomainAuction memory auction, EventRange memory range)
    internal
    view
    returns (uint256 beatPrice)
  {
    beatPrice = Math.max(auction.startingPrice, auction.bid.price);
    // Beats price increases if domain is already bided and the event is not yet ended.
    if (auction.bid.price != 0 && !range.isEnded()) {
      beatPrice += Math.mulDiv(auction.startingPrice, _bidGapRatio, MAX_PERCENTAGE);
    }
  }

  /**
   * @dev Helper method to ensure event range is valid.
   */
  function _requireValidEventRange(EventRange calldata range) internal view {
    if (!(range.valid() && range.isNotYetStarted())) revert InvalidEventRange();
  }

  /**
   * @dev Helper method to ensure the auction is not yet started or not created.
   */
  function _requireNotStarted(bytes32 auctionId) internal view {
    if (!_auctionRange[auctionId].isNotYetStarted()) revert EventIsNotCreatedOrAlreadyStarted();
  }
}
