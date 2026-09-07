// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract } from "script/utils/Contract.sol";
import { RNSDomainPrice } from "src/RNSDomainPrice.sol";
import { ISharedArgument } from "script/interfaces/ISharedArgument.sol";
import { IRONRegistrarController } from "src/interfaces/IRONRegistrarController.sol";
import { IPriceFeedRegistryConsumer } from "src/interfaces/IPriceFeedRegistryConsumer.sol";
import { ChainlinkDataStreamFeed } from "src/libraries/LibChainlinkDataStreamFeed.sol";
import { Migration } from "script/Migration.s.sol";

/**
 * @dev Upgrades RNSDomainPrice to read RON/USD from the PriceFeedRegistry (Chainlink Data Streams) instead of the
 * Chainlink AggregatorV3 proxy, which Chainlink deprecated on 2026-08-26 (mainnet block 60142190). Since then every
 * RON/USD read, and therefore every registration/renewal quote, reverts.
 *
 * The upgrade calls `initializeV3(registry, feedId, maxAcceptableAge)`; the linear storage layout is unchanged because
 * both the old and the new price-feed consumer keep their state in ERC-7201 namespaced slots.
 */
contract Migration__20260904_UpgradeDomainPrice_AdoptPriceFeedRegistry is Migration {
  function _preCheck() internal virtual override {
    (address registry, bytes32 feedId, uint64 maxAcceptableAge) = _expectedPriceFeed();

    assertTrue(IPriceFeedRegistryConsumer(registry).isFeedWhitelisted(feedId), "RON/USD feed is not whitelisted");
    (int192 price,) = IPriceFeedRegistryConsumer(registry).getLatestPriceWithMaxAge(feedId, maxAcceptableAge);
    assertGt(price, 0, "RON/USD price is not positive");
  }

  function _postCheck() internal virtual override {
    RNSDomainPrice domainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));
    _checkPriceFeedConfig(domainPrice);
    _checkConversions(domainPrice);

    super._postCheck();
  }

  function run() public {
    (address registry, bytes32 feedId, uint64 maxAcceptableAge) = _expectedPriceFeed();
    _upgradeProxy(
      Contract.RNSDomainPrice.key(), abi.encodeCall(RNSDomainPrice.initializeV3, (registry, feedId, maxAcceptableAge))
    );
  }

  function _expectedPriceFeed() internal view returns (address registry, bytes32 feedId, uint64 maxAcceptableAge) {
    ISharedArgument.RNSDomainPriceParam memory param = config.sharedArguments().rnsDomainPrice;
    return (param.priceFeedRegistry, param.ronUsdFeedId, param.maxAcceptableAge);
  }

  function _checkPriceFeedConfig(RNSDomainPrice domainPrice) internal view {
    (address registry, bytes32 feedId, uint64 maxAcceptableAge) = _expectedPriceFeed();
    (IPriceFeedRegistryConsumer actualRegistry, ChainlinkDataStreamFeed memory priceFeed) =
      domainPrice.priceRegistryData();

    assertEq(address(actualRegistry), registry, "registry mismatch");
    assertEq(priceFeed._feedId, feedId, "feedId mismatch");
    assertEq(priceFeed._tokenInDecimal, domainPrice.RON_DECIMALS(), "tokenInDecimal mismatch");
    assertEq(priceFeed._tokenOutDecimal, domainPrice.USD_DECIMALS(), "tokenOutDecimal mismatch");
    assertEq(priceFeed._maxAcceptableAge, maxAcceptableAge, "maxAcceptableAge mismatch");
  }

  function _checkConversions(RNSDomainPrice domainPrice) internal view {
    (address registry, bytes32 feedId, uint64 maxAcceptableAge) = _expectedPriceFeed();
    (int192 price, uint8 priceDecimal) =
      IPriceFeedRegistryConsumer(registry).getLatestPriceWithMaxAge(feedId, maxAcceptableAge);
    uint256 ronUsdPrice = uint256(uint192(price));

    // 1 USD in RON == 1 / (RON/USD price), 1 RON in USD == RON/USD price
    uint256 expectedRonPerUsd = 10 ** (18 + priceDecimal) / ronUsdPrice;
    uint256 expectedUsdPerRon = ronUsdPrice * 1e18 / 10 ** priceDecimal;
    assertApproxEqRel(domainPrice.convertUSDToRON(1e18), expectedRonPerUsd, 1e15, "USD -> RON mismatch");
    assertApproxEqRel(domainPrice.convertRONToUSD(1e18), expectedUsdPerRon, 1e15, "RON -> USD mismatch");

    (uint256 usdPrice, uint256 ronPrice) =
      IRONRegistrarController(loadContract(Contract.RONRegistrarController.key())).rentPrice("tudo-hihi-haha", 365 days);
    assertGt(usdPrice, 0, "USD rent price is zero");
    assertApproxEqRel(ronPrice, usdPrice * expectedRonPerUsd / 1e18, 1e15, "RON rent price mismatch");
  }
}
