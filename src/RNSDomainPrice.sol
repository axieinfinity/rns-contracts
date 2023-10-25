// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IPyth, PythStructs } from "@pythnetwork/IPyth.sol";
import { INSUnified } from "./interfaces/INSUnified.sol";
import { INSAuction } from "./interfaces/INSAuction.sol";
import { INSDomainPrice } from "./interfaces/INSDomainPrice.sol";
import { PeriodScaler, LibPeriodScaler, Math } from "./libraries/math/PeriodScalingUtils.sol";
import { TimestampWrapper } from "./libraries/TimestampWrapperUtils.sol";
import { LibSafeRange } from "./libraries/math/LibSafeRange.sol";
import { LibString } from "./libraries/LibString.sol";
import { LibRNSDomain } from "./libraries/LibRNSDomain.sol";
import { PythConverter } from "./libraries/pyth/PythConverter.sol";

contract RNSDomainPrice is Initializable, AccessControlEnumerable, INSDomainPrice {
  using LibString for *;
  using LibRNSDomain for string;
  using LibPeriodScaler for PeriodScaler;
  using PythConverter for PythStructs.Price;

  /// @inheritdoc INSDomainPrice
  uint8 public constant USD_DECIMALS = 18;
  /// @inheritdoc INSDomainPrice
  uint64 public constant MAX_PERCENTAGE = 100_00;
  /// @inheritdoc INSDomainPrice
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  /// @inheritdoc INSDomainPrice
  bytes32 public constant OVERRIDER_ROLE = keccak256("OVERRIDER_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Pyth oracle contract
  IPyth internal _pyth;
  /// @dev RNSAuction contract
  INSAuction internal _auction;
  /// @dev Extra fee for renewals based on the current domain price.
  uint256 internal _taxRatio;
  /// @dev Max length of the renewal fee
  uint256 internal _rnfMaxLength;
  /// @dev Max acceptable age of the price oracle request
  uint256 internal _maxAcceptableAge;
  /// @dev Price feed ID on Pyth for RON/USD
  bytes32 internal _pythIdForRONUSD;
  /// @dev The percentage scale from domain price each period
  PeriodScaler internal _dpDownScaler;

  /// @dev Mapping from domain length => renewal fee in USD
  mapping(uint256 length => uint256 usdPrice) internal _rnFee;
  /// @dev Mapping from name => domain price in USD
  mapping(bytes32 lbHash => TimestampWrapper usdPrice) internal _dp;
  /// @dev Mapping from name => inverse bitwise of renewal fee overriding.
  mapping(bytes32 lbHash => uint256 usdPrice) internal _rnFeeOverriding;

  constructor() payable {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address[] calldata operators,
    RenewalFee[] calldata renewalFees,
    uint256 taxRatio,
    PeriodScaler calldata domainPriceScaleRule,
    IPyth pyth,
    INSAuction auction,
    uint256 maxAcceptableAge,
    bytes32 pythIdForRONUSD
  ) external initializer {
    uint256 length = operators.length;
    bytes32 operatorRole = OPERATOR_ROLE;

    for (uint256 i; i < length;) {
      _setupRole(operatorRole, operators[i]);

      unchecked {
        ++i;
      }
    }
    _auction = auction;
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setRenewalFeeByLengths(renewalFees);
    _setTaxRatio(taxRatio);
    _setDomainPriceScaleRule(domainPriceScaleRule);
    _setPythOracleConfig(pyth, maxAcceptableAge, pythIdForRONUSD);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getPythOracleConfig() external view returns (IPyth pyth, uint256 maxAcceptableAge, bytes32 pythIdForRONUSD) {
    return (_pyth, _maxAcceptableAge, _pythIdForRONUSD);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function setPythOracleConfig(IPyth pyth, uint256 maxAcceptableAge, bytes32 pythIdForRONUSD)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setPythOracleConfig(pyth, maxAcceptableAge, pythIdForRONUSD);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getRenewalFeeByLengths() external view returns (RenewalFee[] memory renewalFees) {
    uint256 rnfMaxLength = _rnfMaxLength;
    renewalFees = new RenewalFee[](rnfMaxLength);
    uint256 len;

    for (uint256 i; i < rnfMaxLength;) {
      unchecked {
        len = i + 1;
        renewalFees[i].labelLength = len;
        renewalFees[i].fee = _rnFee[len];
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function setRenewalFeeByLengths(RenewalFee[] calldata renewalFees) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setRenewalFeeByLengths(renewalFees);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getTaxRatio() external view returns (uint256 ratio) {
    return _taxRatio;
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function setTaxRatio(uint256 ratio) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTaxRatio(ratio);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getScaleDownRuleForDomainPrice() external view returns (PeriodScaler memory scaleRule) {
    return _dpDownScaler;
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function setScaleDownRuleForDomainPrice(PeriodScaler calldata scaleRule) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDomainPriceScaleRule(scaleRule);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getOverriddenRenewalFee(string calldata label) external view returns (uint256 usdFee) {
    usdFee = _rnFeeOverriding[label.hashLabel()];
    if (usdFee == 0) revert RenewalFeeIsNotOverriden();
    return ~usdFee;
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function bulkOverrideRenewalFees(bytes32[] calldata lbHashes, uint256[] calldata usdPrices)
    external
    onlyRole(OVERRIDER_ROLE)
  {
    uint256 length = lbHashes.length;
    if (length == 0 || length != usdPrices.length) revert InvalidArrayLength();
    uint256 inverseBitwise;
    address operator = _msgSender();

    for (uint256 i; i < length;) {
      inverseBitwise = ~usdPrices[i];
      _rnFeeOverriding[lbHashes[i]] = inverseBitwise;
      emit RenewalFeeOverridingUpdated(operator, lbHashes[i], inverseBitwise);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function bulkTrySetDomainPrice(
    bytes32[] calldata lbHashes,
    uint256[] calldata ronPrices,
    bytes32[] calldata proofHashes,
    uint256[] calldata setTypes
  ) external onlyRole(OPERATOR_ROLE) returns (bool[] memory updated) {
    uint256 length = _requireBulkSetDomainPriceArgumentsValid(lbHashes, ronPrices, proofHashes, setTypes);
    address operator = _msgSender();
    updated = new bool[](length);

    for (uint256 i; i < length;) {
      updated[i] = _setDomainPrice(operator, lbHashes[i], ronPrices[i], proofHashes[i], setTypes[i], false);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function bulkSetDomainPrice(
    bytes32[] calldata lbHashes,
    uint256[] calldata ronPrices,
    bytes32[] calldata proofHashes,
    uint256[] calldata setTypes
  ) external onlyRole(OVERRIDER_ROLE) {
    uint256 length = _requireBulkSetDomainPriceArgumentsValid(lbHashes, ronPrices, proofHashes, setTypes);
    address operator = _msgSender();

    for (uint256 i; i < length;) {
      _setDomainPrice(operator, lbHashes[i], ronPrices[i], proofHashes[i], setTypes[i], true);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getDomainPrice(string memory label) public view returns (uint256 usdPrice, uint256 ronPrice) {
    usdPrice = _getDomainPrice(label.hashLabel());
    ronPrice = convertUSDToRON(usdPrice);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function getRenewalFee(string memory label, uint256 duration)
    public
    view
    returns (UnitPrice memory basePrice, UnitPrice memory tax)
  {
    uint256 nameLen = label.strlen();
    bytes32 lbHash = label.hashLabel();
    uint256 overriddenRenewalFee = _rnFeeOverriding[lbHash];

    if (overriddenRenewalFee != 0) {
      basePrice.usd = duration * ~overriddenRenewalFee;
    } else {
      uint256 renewalFeeByLength = _rnFee[Math.min(nameLen, _rnfMaxLength)];
      basePrice.usd = duration * renewalFeeByLength;
      uint256 id = LibRNSDomain.toId(LibRNSDomain.RON_ID, label);
      INSAuction auction = _auction;
      if (auction.reserved(id)) {
        INSUnified rns = auction.getRNSUnified();
        uint256 expiry = LibSafeRange.addWithUpperbound(rns.getRecord(id).mut.expiry, duration, type(uint64).max);
        (INSAuction.DomainAuction memory domainAuction,) = auction.getAuction(id);
        uint256 claimedAt = domainAuction.bid.claimedAt;
        if (claimedAt != 0 && expiry - claimedAt > auction.MAX_AUCTION_DOMAIN_EXPIRY()) {
          revert ExceedAuctionDomainExpiry();
        }
        // Tax is added to the name reserved for the auction
        tax.usd = Math.mulDiv(_taxRatio, _getDomainPrice(lbHash), MAX_PERCENTAGE);
      }
    }

    tax.ron = convertUSDToRON(tax.usd);
    basePrice.ron = convertUSDToRON(basePrice.usd);
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function convertUSDToRON(uint256 usdWei) public view returns (uint256 ronWei) {
    return _pyth.getPriceNoOlderThan(_pythIdForRONUSD, _maxAcceptableAge).inverse({ expo: -18 }).mul({
      inpWei: usdWei,
      inpDecimals: int32(uint32(USD_DECIMALS)),
      outDecimals: 18
    });
  }

  /**
   * @inheritdoc INSDomainPrice
   */
  function convertRONToUSD(uint256 ronWei) public view returns (uint256 usdWei) {
    return _pyth.getPriceNoOlderThan(_pythIdForRONUSD, _maxAcceptableAge).mul({
      inpWei: ronWei,
      inpDecimals: 18,
      outDecimals: int32(uint32(USD_DECIMALS))
    });
  }

  /**
   * @dev Reverts if the arguments of the method {bulkSetDomainPrice} is invalid.
   */
  function _requireBulkSetDomainPriceArgumentsValid(
    bytes32[] calldata lbHashes,
    uint256[] calldata ronPrices,
    bytes32[] calldata proofHashes,
    uint256[] calldata setTypes
  ) internal pure returns (uint256 length) {
    length = lbHashes.length;
    if (length == 0 || ronPrices.length != length || proofHashes.length != length || setTypes.length != length) {
      revert InvalidArrayLength();
    }
  }

  /**
   * @dev Helper method to set domain price.
   *
   * Emits an event {DomainPriceUpdated} optionally.
   */
  function _setDomainPrice(
    address operator,
    bytes32 lbHash,
    uint256 ronPrice,
    bytes32 proofHash,
    uint256 setType,
    bool forced
  ) internal returns (bool updated) {
    uint256 usdPrice = convertRONToUSD(ronPrice);
    TimestampWrapper storage dp = _dp[lbHash];
    updated = forced || dp.value < usdPrice;

    if (updated) {
      dp.value = usdPrice;
      dp.timestamp = block.timestamp;
      emit DomainPriceUpdated(operator, lbHash, usdPrice, proofHash, setType);
    }
  }

  /**
   * @dev Sets renewal reservation ratio.
   *
   * Emits an event {TaxRatioUpdated}.
   */
  function _setTaxRatio(uint256 ratio) internal {
    _taxRatio = ratio;
    emit TaxRatioUpdated(_msgSender(), ratio);
  }

  /**
   * @dev Sets domain price scale rule.
   *
   * Emits events {DomainPriceScaleRuleUpdated}.
   */
  function _setDomainPriceScaleRule(PeriodScaler calldata domainPriceScaleRule) internal {
    _dpDownScaler = domainPriceScaleRule;
    emit DomainPriceScaleRuleUpdated(_msgSender(), domainPriceScaleRule.ratio, domainPriceScaleRule.period);
  }

  /**
   * @dev Sets renewal fee.
   *
   * Emits events {RenewalFeeByLengthUpdated}.
   * Emits an event {MaxRenewalFeeLengthUpdated} optionally.
   */
  function _setRenewalFeeByLengths(RenewalFee[] calldata renewalFees) internal {
    address operator = _msgSender();
    RenewalFee memory renewalFee;
    uint256 length = renewalFees.length;
    uint256 maxRenewalFeeLength = _rnfMaxLength;

    for (uint256 i; i < length;) {
      renewalFee = renewalFees[i];
      maxRenewalFeeLength = Math.max(maxRenewalFeeLength, renewalFee.labelLength);
      _rnFee[renewalFee.labelLength] = renewalFee.fee;
      emit RenewalFeeByLengthUpdated(operator, renewalFee.labelLength, renewalFee.fee);

      unchecked {
        ++i;
      }
    }

    if (maxRenewalFeeLength != _rnfMaxLength) {
      _rnfMaxLength = maxRenewalFeeLength;
      emit MaxRenewalFeeLengthUpdated(operator, maxRenewalFeeLength);
    }
  }

  /**
   * @dev Sets Pyth Oracle config.
   *
   * Emits events {PythOracleConfigUpdated}.
   */
  function _setPythOracleConfig(IPyth pyth, uint256 maxAcceptableAge, bytes32 pythIdForRONUSD) internal {
    _pyth = pyth;
    _maxAcceptableAge = maxAcceptableAge;
    _pythIdForRONUSD = pythIdForRONUSD;
    emit PythOracleConfigUpdated(_msgSender(), pyth, maxAcceptableAge, pythIdForRONUSD);
  }

  /**
   * @dev Returns the current domain price applied the business rule: deduced x% each y seconds.
   */
  function _getDomainPrice(bytes32 lbHash) internal view returns (uint256) {
    TimestampWrapper storage dp = _dp[lbHash];
    uint256 lastSyncedAt = dp.timestamp;
    if (lastSyncedAt == 0) return 0;

    uint256 passedDuration = block.timestamp - lastSyncedAt;
    return _dpDownScaler.scaleDown({ v: dp.value, maxR: MAX_PERCENTAGE, dur: passedDuration });
  }
}
