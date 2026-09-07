// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IPriceFeedRegistryConsumer } from "../interfaces/IPriceFeedRegistryConsumer.sol";

/**
 * @notice Per-pair configuration for a Chainlink Data Streams feed.
 * @dev    The PriceFeedRegistry pointer is intentionally *not* stored here —
 *         it lives once on the owning consumer
 *         ({PriceFeedRegistryConsumerUpgradeable}). The price's decimal
 *         precision is *also* not stored here — it lives on the registry
 *         (registered at whitelist time) and is returned alongside the
 *         price by {IPriceFeedRegistryConsumer-getLatestPriceWithMaxAge},
 *         which keeps oracle-format metadata in a single source of truth
 *         and lets one consumer transparently use feeds of differing
 *         precision.
 * @param _feedId           The Chainlink Data Streams feedId to read.
 * @param _tokenInDecimal   Decimal precision of token in.
 * @param _tokenOutDecimal  Decimal precision of token out.
 * @param _maxAcceptableAge Max age (seconds) tolerated for an observed price.
 */
struct ChainlinkDataStreamFeed {
  bytes32 _feedId;
  uint8 _tokenInDecimal;
  uint8 _tokenOutDecimal;
  uint64 _maxAcceptableAge;
}

using LibChainlinkDataStreamFeed for ChainlinkDataStreamFeed global;

/**
 * @title LibChainlinkDataStreamFeed
 * @notice Aggregator-free counterpart to the legacy LibChainlinkPriceFeed.
 *         Reads verified prices from a {PriceFeedRegistry} (Chainlink Data
 *         Streams) and exposes the same conversion surface so call sites
 *         that already use the legacy library can migrate with minimal churn.
 */
library LibChainlinkDataStreamFeed {
  /// @dev Decimal bound for scalePrice math — guards 10**n against overflow.
  uint8 internal constant _DECIMAL_LIMIT = 30;
  /// @dev floor(log10(2**256 - 1)).
  uint8 internal constant _MAX_DECIMAL = 77;

  /// @dev Thrown when a configured decimal exceeds the safety bound.
  error LargeDecimal(uint8 decimal);
  /// @dev Thrown when the scaled price would overflow.
  error ComputedPriceTooLarge(uint256 price, int8 expo);
  /// @dev Thrown when the scaled price would underflow to zero.
  error ComputedPriceTooSmall(uint256 price, int8 expo);
  /// @dev Thrown when the registry returns a non-positive price.
  error PanicNegativeQuotePrice(int192 answer);
  /// @dev Thrown when the feedId is zero on set().
  error ZeroFeedId();

  /// @dev Emitted when the feed config is (re)written.
  event ChainlinkDataStreamFeedUpdated(bytes32 indexed feedId, uint8 tokenInDecimal, uint8 tokenOutDecimal);
  /// @dev Emitted when max acceptable age is rewritten in place.
  event MaxAcceptableAgeUpdated(bytes32 indexed feedId, uint64 maxAcceptableAge);

  /**
   * @dev Sets the Data Streams feed config for a token pair.
   */
  function set(
    ChainlinkDataStreamFeed storage $,
    bytes32 feedId,
    uint8 tokenInDecimal,
    uint8 tokenOutDecimal,
    uint64 maxAcceptableAge
  ) internal {
    if (feedId == bytes32(0)) revert ZeroFeedId();
    if (tokenInDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenInDecimal);
    if (tokenOutDecimal > _DECIMAL_LIMIT) revert LargeDecimal(tokenOutDecimal);

    $._feedId = feedId;
    $._tokenInDecimal = tokenInDecimal;
    $._tokenOutDecimal = tokenOutDecimal;
    $._maxAcceptableAge = maxAcceptableAge;

    emit ChainlinkDataStreamFeedUpdated(feedId, tokenInDecimal, tokenOutDecimal);
    emit MaxAcceptableAgeUpdated(feedId, maxAcceptableAge);
  }

  /**
   * @dev Updates the heartbeat (max acceptable age) for the price.
   */
  function setMaxAcceptableAge(ChainlinkDataStreamFeed storage $, uint64 maxAcceptableAge) internal {
    $._maxAcceptableAge = maxAcceptableAge;
    emit MaxAcceptableAgeUpdated($._feedId, maxAcceptableAge);
  }

  /**
   * @dev Convert a token-in amount into the token-out amount using the
   *      latest verified Data Streams price from `registry`.
   */
  function convertTokenIn2TokenOut(
    ChainlinkDataStreamFeed memory priceFeed,
    IPriceFeedRegistryConsumer registry,
    uint256 tokenInAmount
  ) internal view returns (uint256 tokenOutAmount) {
    (uint256 price, uint8 priceDecimal) = quotePrice(priceFeed, registry);
    uint256 scaledPrice = _scalePrice(price, priceDecimal, priceFeed._tokenOutDecimal);
    tokenOutAmount = Math.mulDiv(scaledPrice, tokenInAmount, 10 ** priceFeed._tokenInDecimal);
  }

  /**
   * @dev Convert a token-out amount into the token-in amount (1/price).
   */
  function convertTokenOut2TokenIn(
    ChainlinkDataStreamFeed memory priceFeed,
    IPriceFeedRegistryConsumer registry,
    uint256 tokenOutAmount
  ) internal view returns (uint256 tokenInAmount) {
    (uint256 price, uint8 priceDecimal) = quotePrice(priceFeed, registry);
    uint256 inversedPrice = _inverseAndScalePrice(price, priceDecimal, priceFeed._tokenInDecimal);
    tokenInAmount = Math.mulDiv(inversedPrice, tokenOutAmount, 10 ** priceFeed._tokenOutDecimal);
  }

  /**
   * @dev Reads the latest verified price (and its decimal precision) from
   *      `registry`, enforcing the configured heartbeat. Bubbles up
   *      registry reverts on stale / unset / expired data and rejects
   *      non-positive prices defensively.
   */
  function quotePrice(ChainlinkDataStreamFeed memory priceFeed, IPriceFeedRegistryConsumer registry)
    internal
    view
    returns (uint256 price, uint8 priceDecimal)
  {
    (int192 answer, uint8 decimals) = registry.getLatestPriceWithMaxAge(priceFeed._feedId, priceFeed._maxAcceptableAge);
    if (answer <= 0) revert PanicNegativeQuotePrice(answer);
    if (decimals > _DECIMAL_LIMIT) revert LargeDecimal(decimals);

    return (uint256(uint192(answer)), decimals);
  }

  /**
   * @dev Scales `price` from `priceDecimal` to `desiredDecimal`, guarded.
   *      Matches the legacy LibChainlinkPriceFeed.scalePrice surface so
   *      consumers migrating from the aggregator-based library see the
   *      same overflow/underflow reverts and the same scaled outputs.
   */
  function _scalePrice(uint256 price, uint8 priceDecimal, uint8 desiredDecimal)
    private
    pure
    returns (uint256 scaledPrice)
  {
    uint256 log10Price = Math.log10(price);
    if (desiredDecimal > priceDecimal) {
      if (log10Price + (desiredDecimal - priceDecimal) > _MAX_DECIMAL) {
        revert ComputedPriceTooLarge(price, -(int8(desiredDecimal) - int8(priceDecimal)));
      }
    } else if (desiredDecimal < priceDecimal) {
      if (log10Price < priceDecimal - desiredDecimal) {
        revert ComputedPriceTooSmall(price, -(int8(priceDecimal) - int8(desiredDecimal)));
      }
    }
    return _exp10(price, int32(int8(desiredDecimal)) - int32(int8(priceDecimal)));
  }

  /// @dev Inlined `LibPowMath.exp10` — multiplies `x` by 10^n with a
  ///      signed exponent. Kept here to avoid pulling in the legacy
  ///      LibPowMath dependency.
  function _exp10(uint256 x, int32 n) private pure returns (uint256) {
    if (n < 0) return x / 10 ** uint32(-n);
    if (n > 0) return x * 10 ** uint32(n);
    return x;
  }

  /**
   * @dev Inverts an (A/B) price into (B/A) at `desiredDecimal` precision.
   */
  function _inverseAndScalePrice(uint256 price, uint8 priceDecimal, uint8 desiredDecimal)
    private
    pure
    returns (uint256)
  {
    if (priceDecimal + desiredDecimal > _MAX_DECIMAL) {
      revert LargeDecimal(priceDecimal + desiredDecimal);
    }
    if (price > 10 ** (desiredDecimal + priceDecimal)) {
      revert ComputedPriceTooLarge(price, -(int8(desiredDecimal) - int8(priceDecimal)));
    }

    return 10 ** (desiredDecimal + priceDecimal) / price;
  }
}
