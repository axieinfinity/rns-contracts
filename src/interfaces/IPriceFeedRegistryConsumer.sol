// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPriceFeedRegistryConsumer
 * @notice Strict read-only surface of the PriceFeedRegistry, intended for
 *         downstream contracts that consume verified prices.
 *
 *         Functions in this interface MUST revert rather than return a
 *         silently-wrong value when the price cannot be trusted (never
 *         observed, expired, not yet active, or older than the caller's
 *         freshness bound). Returning a zero or stale price could be
 *         catastrophic for consumers (mispriced trades, undercollateralised
 *         loans), so the registry forces callers into a fail-closed
 *         posture.
 *
 *         For raw access to the storage struct (no checks), import
 *         IPriceFeedRegistry instead.
 */
interface IPriceFeedRegistryConsumer {
  // ----------------- Errors -----------------

  /// @notice The feed has never received a verified report. Default storage.
  error PriceNotAvailable(bytes32 feedId);

  /// @notice The latest verified report for `feedId` has passed its
  ///         `expiresAt` according to `block.timestamp`.
  error PriceExpired(bytes32 feedId, uint32 expiresAt, uint256 currentTimestamp);

  /// @notice The latest verified report's `validFromTimestamp` is in the
  ///         future. Defensive — should not happen in normal operation.
  error PriceNotYetActive(bytes32 feedId, uint32 validFromTimestamp, uint256 currentTimestamp);

  /// @notice The latest verified report is older than the caller's
  ///         freshness bound (`maxAgeSeconds`). Used by callers that need
  ///         a tighter heartbeat than `expiresAt`.
  error PriceTooOld(bytes32 feedId, uint32 observationsTimestamp, uint256 maxAgeSeconds, uint256 currentTimestamp);

  // ----------------- External: views -----------------

  /**
   * @notice Latest verified price for `feedId`, enforcing that the report
   *         is no older than `maxAgeSeconds` in addition to the registry's
   *         own freshness window (`validFromTimestamp` ≤ now < `expiresAt`).
   * @dev    Reverts with {PriceNotAvailable}, {PriceExpired},
   *         {PriceNotYetActive}, or {PriceTooOld} when the price cannot
   *         be trusted. Callers that genuinely want no extra age bound
   *         on top of `expiresAt` can pass `type(uint256).max`.
   *         Returns the price together with its configured decimal so
   *         callers do not need a second round-trip via {getDecimals}.
   */
  function getLatestPriceWithMaxAge(bytes32 feedId, uint256 maxAgeSeconds)
    external
    view
    returns (int192 price, uint8 priceDecimal);

  /**
   * @notice Decimal precision of the price reported under `feedId`,
   *         as registered with the registry's whitelist. Returns 0 if
   *         `feedId` has never been whitelisted.
   */
  function getDecimals(bytes32 feedId) external view returns (uint8);

  /**
   * @notice Whether `feedId` is currently part of the registry's whitelist.
   *         Useful for consumer-side preflight checks.
   */
  function isFeedWhitelisted(bytes32 feedId) external view returns (bool);
}
