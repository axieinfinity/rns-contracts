// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IPriceFeedRegistryConsumer } from "../interfaces/IPriceFeedRegistryConsumer.sol";
import { ChainlinkDataStreamFeed, LibChainlinkDataStreamFeed } from "../libraries/LibChainlinkDataStreamFeed.sol";

/**
 * @title PriceFeedRegistryConsumerUpgradeable
 * @notice Upgradeable counterpart of {PriceFeedRegistryConsumer}. Behaves
 *         identically — strict, fail-closed reads PLUS per-pair convert
 *         helpers backed by a single {ChainlinkDataStreamFeed} config —
 *         but stores both the registry pointer and the feed config in
 *         ERC-7201 namespaced storage so it's safe to inherit from a
 *         proxy-based implementation contract.
 *
 *         The registry is set once via {__PriceFeedRegistryConsumer_init}
 *         and is intentionally not exposed via a setter. Rotating the
 *         registry requires deploying a new implementation and upgrading
 *         the proxy — this matches how the non-upgradeable base treats it
 *         as `immutable`.
 *
 *         Inheriting contracts MUST NOT declare additional non-namespaced
 *         state variables; follow the same ERC-7201 discipline for any
 *         storage they add themselves.
 *
 *         Example:
 *
 *         ```solidity
 *         contract AxsChargerUpgradeable is
 *             Initializable,
 *             OwnableUpgradeable,
 *             PriceFeedRegistryConsumerUpgradeable
 *         {
 *             /// @custom:oz-upgrades-unsafe-allow constructor
 *             constructor() { _disableInitializers(); }
 *
 *             function initialize(address owner_, address registry) external initializer {
 *                 __Ownable_init(owner_);
 *                 __PriceFeedRegistryConsumer_init(registry);
 *                 _updatePriceFeed({
 *                     feedId: AXS_USD_FEED_ID,
 *                     tokenInDecimal: 6,
 *                     tokenOutDecimal: 18,
 *                     maxAcceptableAge: 60
 *                 });
 *             }
 *
 *             function chargeUsd(uint256 usdAmount) external view returns (uint256) {
 *                 return _convertTokenOut2TokenIn(usdAmount);
 *             }
 *         }
 *         ```
 */
abstract contract PriceFeedRegistryConsumerUpgradeable {
  using LibChainlinkDataStreamFeed for ChainlinkDataStreamFeed;

  error ZeroRegistryAddress();

  event PriceFeedRegistryUpdated(address indexed registry);
  event PriceFeedUpdated(bytes32 indexed feedId, uint8 tokenInDecimal, uint8 tokenOutDecimal, uint64 maxAcceptableAge);

  /// @custom:storage-location erc7201:ronin.storage.PriceFeedRegistryConsumer
  struct PriceFeedRegistryConsumerStorageLayout {
    IPriceFeedRegistryConsumer registry;
    ChainlinkDataStreamFeed priceFeed;
  }

  // keccak256(abi.encode(uint256(keccak256("ronin.storage.PriceFeedRegistryConsumer")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant PriceFeedRegistryConsumerStorageLocation =
    0xd0ddcb5113548a45dce7053ef63d0d5b9cda75121765cec96863b21497484d00;

  function _getPriceFeedRegistryConsumerStorage()
    internal
    pure
    returns (PriceFeedRegistryConsumerStorageLayout storage $)
  {
    assembly {
      $.slot := PriceFeedRegistryConsumerStorageLocation
    }
  }

  // ----------------- Public view -----------------

  /// @notice The trusted price registry this contract reads from, together
  ///         with the per-pair feed config used by the convert helpers.
  function priceRegistryData()
    public
    view
    returns (IPriceFeedRegistryConsumer registry, ChainlinkDataStreamFeed memory priceFeed)
  {
    PriceFeedRegistryConsumerStorageLayout storage $ = _getPriceFeedRegistryConsumerStorage();
    return ($.registry, $.priceFeed);
  }

  // ----------------- Raw read -----------------

  /// @dev See {PriceFeedRegistryConsumer-_priceOf}.
  function _priceOf(bytes32 feedId, uint256 maxAgeSeconds) internal view returns (int192) {
    (int192 price,) = _getPriceFeedRegistryConsumerStorage().registry.getLatestPriceWithMaxAge(feedId, maxAgeSeconds);
    return price;
  }

  // ----------------- Feed config -----------------

  function _updatePriceFeedRegistry(address registry) internal {
    if (registry == address(0)) revert ZeroRegistryAddress();
    _getPriceFeedRegistryConsumerStorage().registry = IPriceFeedRegistryConsumer(registry);

    emit PriceFeedRegistryUpdated(registry);
  }

  /// @dev Writes the per-pair feed config used by the convert helpers.
  ///      The price's decimal precision is *not* tracked here — it lives
  ///      on the registry (set at whitelist time) and is returned with
  ///      the price by {IPriceFeedRegistryConsumer-getLatestPriceWithMaxAge}.
  function _updatePriceFeed(bytes32 feedId, uint8 tokenInDecimal, uint8 tokenOutDecimal, uint64 maxAcceptableAge)
    internal
  {
    _getPriceFeedRegistryConsumerStorage().priceFeed.set(feedId, tokenInDecimal, tokenOutDecimal, maxAcceptableAge);

    emit PriceFeedUpdated(feedId, tokenInDecimal, tokenOutDecimal, maxAcceptableAge);
  }

  // ----------------- Convert / quote -----------------

  /// @dev Convert a token-in amount into the token-out amount using the
  ///      stored feed config and the stored registry.
  function _convertTokenIn2TokenOut(uint256 tokenInAmount) internal view returns (uint256 tokenOutAmount) {
    PriceFeedRegistryConsumerStorageLayout storage $ = _getPriceFeedRegistryConsumerStorage();
    tokenOutAmount = $.priceFeed.convertTokenIn2TokenOut($.registry, tokenInAmount);
  }

  /// @dev Convert a token-out amount into the token-in amount (1/price).
  function _convertTokenOut2TokenIn(uint256 tokenOutAmount) internal view returns (uint256 tokenInAmount) {
    PriceFeedRegistryConsumerStorageLayout storage $ = _getPriceFeedRegistryConsumerStorage();
    tokenInAmount = $.priceFeed.convertTokenOut2TokenIn($.registry, tokenOutAmount);
  }
}
