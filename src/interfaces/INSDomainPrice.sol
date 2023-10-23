//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PeriodScaler } from "../libraries/math/PeriodScalingUtils.sol";
import { IPyth } from "@pythnetwork/IPyth.sol";

interface INSDomainPrice {
  error InvalidArrayLength();
  error RenewalFeeIsNotOverriden();
  error ExceedAuctionDomainExpiry();

  struct RenewalFee {
    uint256 labelLength;
    uint256 fee;
  }

  struct UnitPrice {
    uint256 usd;
    uint256 ron;
  }

  /// @dev Emitted when the renewal reservation ratio is updated.
  event TaxRatioUpdated(address indexed operator, uint256 indexed ratio);
  /// @dev Emitted when the maximum length of renewal fee is updated.
  event MaxRenewalFeeLengthUpdated(address indexed operator, uint256 indexed maxLength);
  /// @dev Emitted when the renew fee is updated.
  event RenewalFeeByLengthUpdated(address indexed operator, uint256 indexed labelLength, uint256 renewalFee);
  /// @dev Emitted when the renew fee of a domain is overridden. Value of `inverseRenewalFee` is 0 when not overridden.
  event RenewalFeeOverridingUpdated(address indexed operator, bytes32 indexed labelHash, uint256 inverseRenewalFee);

  /// @dev Emitted when the domain price is updated.
  event DomainPriceUpdated(
    address indexed operator, bytes32 indexed labelHash, uint256 price, bytes32 indexed proofHash, uint256 setType
  );
  /// @dev Emitted when the rule to rescale domain price is updated.
  event DomainPriceScaleRuleUpdated(address indexed operator, uint192 ratio, uint64 period);

  /// @dev Emitted when the Pyth Oracle config is updated.
  event PythOracleConfigUpdated(
    address indexed operator, IPyth indexed pyth, uint256 maxAcceptableAge, bytes32 indexed pythIdForRONUSD
  );

  /**
   * @dev Returns the Pyth oracle config.
   */
  function getPythOracleConfig() external view returns (IPyth pyth, uint256 maxAcceptableAge, bytes32 pythIdForRONUSD);

  /**
   * @dev Sets the Pyth oracle config.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits events {PythOracleConfigUpdated}.
   */
  function setPythOracleConfig(IPyth pyth, uint256 maxAcceptableAge, bytes32 pythIdForRONUSD) external;

  /**
   * @dev Returns the percentage to scale from domain price each period.
   */
  function getScaleDownRuleForDomainPrice() external view returns (PeriodScaler memory dpScaleRule);

  /**
   * @dev Sets the percentage to scale from domain price each period.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits events {DomainPriceScaleRuleUpdated}.
   *
   * @notice Applies for the business rule: -x% each y seconds.
   */
  function setScaleDownRuleForDomainPrice(PeriodScaler calldata scaleRule) external;

  /**
   * @dev Returns the renewal fee by lengths.
   */
  function getRenewalFeeByLengths() external view returns (RenewalFee[] memory renewalFees);

  /**
   * @dev Sets the renewal fee by lengths
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits events {RenewalFeeByLengthUpdated}.
   * Emits an event {MaxRenewalFeeLengthUpdated} optionally.
   */
  function setRenewalFeeByLengths(RenewalFee[] calldata renewalFees) external;

  /**
   * @dev Returns tax ratio.
   */
  function getTaxRatio() external view returns (uint256 taxRatio);

  /**
   * @dev Sets renewal reservation ratio.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits an event {TaxRatioUpdated}.
   */
  function setTaxRatio(uint256 ratio) external;

  /**
   * @dev Return the domain price.
   * @param label The domain label to register (Eg, 'foo' for 'foo.ron').
   */
  function getDomainPrice(string memory label) external view returns (uint256 usdPrice, uint256 ronPrice);

  /**
   * @dev Returns the renewal fee in USD and RON.
   * @param label The domain label to register (Eg, 'foo' for 'foo.ron').
   * @param duration Amount of second(s).
   */
  function getRenewalFee(string calldata label, uint256 duration)
    external
    view
    returns (UnitPrice memory basePrice, UnitPrice memory tax);

  /**
   * @dev Returns the renewal fee of a label. Reverts if not overridden.
   * @notice This method is to help developers check the domain renewal fee overriding. Consider using method
   * {getRenewalFee} instead for full handling of renewal fees.
   */
  function getOverriddenRenewalFee(string memory label) external view returns (uint256 usdFee);

  /**
   * @dev Bulk override renewal fees.
   *
   * Requirements:
   * - The method caller is operator.
   * - The input array lengths must be larger than 0 and the same.
   *
   * Emits events {RenewalFeeOverridingUpdated}.
   *
   * @param lbHashes Array of label hashes. (Eg, ['foo'].map(keccak256) for 'foo.ron')
   * @param usdPrices Array of prices in USD. Leave 2^256 - 1 to remove overriding.
   */
  function bulkOverrideRenewalFees(bytes32[] calldata lbHashes, uint256[] calldata usdPrices) external;

  /**
   * @dev Bulk try to set domain prices. Returns a boolean array indicating whether domain prices at the corresponding
   * indexes if set or not.
   *
   * Requirements:
   * - The method caller is operator.
   * - The input array lengths must be larger than 0 and the same.
   * - The price should be larger than current domain price or it will not be updated.
   *
   * Emits events {DomainPriceUpdated} optionally.
   *
   * @param lbHashes Array of label hashes. (Eg, ['foo'].map(keccak256) for 'foo.ron')
   * @param ronPrices Array of prices in (W)RON token.
   * @param proofHashes Array of proof hashes.
   * @param setTypes Array of update types from the operator service.
   */
  function bulkTrySetDomainPrice(
    bytes32[] calldata lbHashes,
    uint256[] calldata ronPrices,
    bytes32[] calldata proofHashes,
    uint256[] calldata setTypes
  ) external returns (bool[] memory updated);

  /**
   * @dev Bulk override domain prices.
   *
   * Requirements:
   * - The method caller is operator.
   * - The input array lengths must be larger than 0 and the same.
   *
   * Emits events {DomainPriceUpdated}.
   *
   * @param lbHashes Array of label hashes. (Eg, ['foo'].map(keccak256) for 'foo.ron')
   * @param ronPrices Array of prices in (W)RON token.
   * @param proofHashes Array of proof hashes.
   * @param setTypes Array of update types from the operator service.
   */
  function bulkSetDomainPrice(
    bytes32[] calldata lbHashes,
    uint256[] calldata ronPrices,
    bytes32[] calldata proofHashes,
    uint256[] calldata setTypes
  ) external;

  /**
   * @dev Returns the converted amount from USD to RON.
   */
  function convertUSDToRON(uint256 usdAmount) external view returns (uint256 ronAmount);

  /**
   * @dev Returns the converted amount from RON to USD.
   */
  function convertRONToUSD(uint256 ronAmount) external view returns (uint256 usdAmount);

  /**
   * @dev Value equals to keccak256("OPERATOR_ROLE").
   */
  function OPERATOR_ROLE() external pure returns (bytes32);

  /**
   * @dev Max percentage 100%. Values [0; 100_00] reflexes [0; 100%]
   */
  function MAX_PERCENTAGE() external pure returns (uint64);

  /**
   * @dev Decimal for USD.
   */
  function USD_DECIMALS() external pure returns (uint8);
}
