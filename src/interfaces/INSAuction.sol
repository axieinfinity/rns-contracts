// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { INSUnified } from "./INSUnified.sol";
import { EventRange } from "../libraries/LibEventRange.sol";

interface INSAuction {
  error NotYetEnded();
  error NoOneBidded();
  error NullAssignment();
  error AlreadyBidding();
  error RatioIsTooLarge();
  error NameNotReserved();
  error InvalidEventRange();
  error QueryIsNotInPeriod();
  error InsufficientAmount();
  error InvalidArrayLength();
  error ContractBidderIsForbidden();
  error EventIsNotCreatedOrAlreadyStarted();

  struct Bid {
    address payable bidder;
    uint256 price;
    uint256 timestamp;
    uint256 claimedAt;
  }

  struct DomainAuction {
    bytes32 auctionId;
    uint256 startingPrice;
    Bid bid;
  }

  /// @dev Emitted when an auction is set.
  event AuctionEventSet(bytes32 indexed auctionId, EventRange range);
  /// @dev Emitted when the labels are listed for auction.
  event LabelsListed(bytes32 indexed auctionId, uint256[] ids, uint256[] startingPrices);
  /// @dev Emitted when a bid is placed for a name.
  event BidPlaced(
    bytes32 indexed auctionId,
    uint256 indexed id,
    uint256 price,
    address payable bidder,
    uint256 previousPrice,
    address previousBidder
  );
  /// @dev Emitted when the treasury is updated.
  event TreasuryUpdated(address indexed addr);
  /// @dev Emitted when bid gap ratio is updated.
  event BidGapRatioUpdated(uint256 ratio);

  /**
   * @dev The maximum expiry duration
   */
  function MAX_EXPIRY() external pure returns (uint64);

  /**
   * @dev The maximum expiry duration of a domain after transferring to bidder.
   */
  function MAX_AUCTION_DOMAIN_EXPIRY() external pure returns (uint64);

  /**
   * @dev Returns the operator role.
   */
  function OPERATOR_ROLE() external pure returns (bytes32);

  /**
   * @dev Max percentage 100%. Values [0; 100_00] reflexes [0; 100%]
   */
  function MAX_PERCENTAGE() external pure returns (uint256);

  /**
   * @dev The expiry duration of a domain after transferring to bidder.
   */
  function DOMAIN_EXPIRY_DURATION() external pure returns (uint64);

  /**
   * @dev Claims domain names for auction.
   *
   * Requirements:
   * - The method caller must be contract operator.
   *
   * @param labels The domain names. Eg, ['foo'] for 'foo.ron'
   * @return ids The id corresponding for namehash of domain names.
   */
  function bulkRegister(string[] calldata labels) external returns (uint256[] memory ids);

  /**
   * @dev Checks whether a domain name is currently reserved for auction or not.
   * @param id The namehash id of domain name. Eg, namehash('foo.ron') for 'foo.ron'
   */
  function reserved(uint256 id) external view returns (bool);

  /**
   * @dev Creates a new auction to sale with a specific time period.
   *
   * Requirements:
   * - The method caller must be admin.
   *
   * Emits an event {AuctionEventSet}.
   *
   * @return auctionId The auction id
   * @notice Please use the method `setAuctionNames` to list all the reserved names.
   */
  function createAuctionEvent(EventRange calldata range) external returns (bytes32 auctionId);

  /**
   * @dev Updates the auction details.
   *
   * Requirements:
   * - The method caller must be admin.
   *
   * Emits an event {AuctionEventSet}.
   */
  function setAuctionEvent(bytes32 auctionId, EventRange calldata range) external;

  /**
   * @dev Returns the event range of an auction.
   */
  function getAuctionEvent(bytes32 auctionId) external view returns (EventRange memory);

  /**
   * @dev Lists reserved names to sale in a specified auction.
   *
   * Requirements:
   * - The method caller must be contract operator.
   * - Array length are matched and larger than 0.
   * - Only allow to set when the domain is:
   *   + Not in any auction.
   *   + Or, in the current auction.
   *   + Or, this name is not bided.
   *
   * Emits an event {LabelsListed}.
   *
   * Note: If the name is already listed, this method replaces with a new input value.
   *
   * @param ids The namehashes id of domain names. Eg, namehash('foo.ron') for 'foo.ron'
   */
  function listNamesForAuction(bytes32 auctionId, uint256[] calldata ids, uint256[] calldata startingPrices) external;

  /**
   * @dev Places a bid for a domain name.
   *
   * Requirements:
   * - The name is listed, or the auction is happening.
   * - The msg.value is larger than the current bid price or the auction starting price.
   *
   * Emits an event {BidPlaced}.
   *
   * @param id The namehash id of domain name. Eg, namehash('foo.ron') for 'foo.ron'
   */
  function placeBid(uint256 id) external payable;

  /**
   * @dev Returns the highest bid and address of the bidder.
   * @param id The namehash id of domain name. Eg, namehash('foo.ron') for 'foo.ron'
   */
  function getAuction(uint256 id) external view returns (DomainAuction memory, uint256 beatPrice);

  /**
   * @dev Bulk claims the bid name.
   *
   * Requirements:
   * - Must be called after ended time.
   * - The method caller can be anyone.
   *
   * @param ids The namehash id of domain name. Eg, namehash('foo.ron') for 'foo.ron'
   */
  function bulkClaimBidNames(uint256[] calldata ids) external returns (uint256[] memory claimedAts);

  /**
   * @dev Returns the treasury.
   */
  function getTreasury() external view returns (address);

  /**
   * @dev Returns the gap ratio between 2 bids with the starting price. Value in range [0;100_00] is 0%-100%.
   */
  function getBidGapRatio() external view returns (uint256);

  /**
   * @dev Sets the treasury.
   *
   * Requirements:
   * - The method caller must be admin
   *
   * Emits an event {TreasuryUpdated}.
   */
  function setTreasury(address payable) external;

  /**
   * @dev Sets commission ratio. Value in range [0;100_00] is 0%-100%.
   *
   * Requirements:
   * - The method caller must be admin
   *
   * Emits an event {BidGapRatioUpdated}.
   */
  function setBidGapRatio(uint256) external;

  /**
   * @dev Returns RNSUnified contract.
   */
  function getRNSUnified() external view returns (INSUnified);
}
