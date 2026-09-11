// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { RNSDomainPrice, INSDomainPrice, INSAuction, PeriodScaler } from "src/RNSDomainPrice.sol";
import { IPriceFeedRegistryConsumer } from "src/interfaces/IPriceFeedRegistryConsumer.sol";
import { ChainlinkDataStreamFeed } from "src/libraries/LibChainlinkDataStreamFeed.sol";
import { PriceFeedRegistryConsumerUpgradeable } from "src/extensions/PriceFeedRegistryConsumerUpgradeable.sol";

contract RNSDomainPricePriceFeedRegistryTest is Test {
  using Strings for *;

  bytes32 internal constant RON_USD_FEED_ID = keccak256("RON/USD");
  uint64 internal constant MAX_ACCEPTABLE_AGE = 24 hours;
  /// @dev 0.05 USD per RON, 18 decimals
  int192 internal constant RON_USD_PRICE = 0.05 ether;

  address internal _admin = makeAddr("admin");
  address internal _proxyAdmin = makeAddr("proxyAdmin");
  address internal _stranger = makeAddr("stranger");
  address internal _auction = makeAddr("auction");

  MockPriceFeedRegistry internal _registry;
  RNSDomainPrice internal _domainPrice;

  function setUp() public {
    vm.warp(1_788_500_000);

    _registry = new MockPriceFeedRegistry();
    _registry.setDecimals(RON_USD_FEED_ID, 18);
    _registry.setPrice(RON_USD_FEED_ID, RON_USD_PRICE, uint32(block.timestamp));

    INSDomainPrice.RenewalFee[] memory renewalFees = new INSDomainPrice.RenewalFee[](1);
    renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
    address[] memory operators = new address[](1);
    operators[0] = _admin;

    RNSDomainPrice logic = new RNSDomainPrice();
    _domainPrice = RNSDomainPrice(
      address(
        new TransparentUpgradeableProxy(
          address(logic),
          _proxyAdmin,
          abi.encodeCall(
            RNSDomainPrice.initialize,
            (
              _admin,
              operators,
              renewalFees,
              1500,
              PeriodScaler({ ratio: 500, period: 30 days * 3 }),
              INSAuction(_auction)
            )
          )
        )
      )
    );
    _domainPrice.initializeV3(address(_registry), RON_USD_FEED_ID, MAX_ACCEPTABLE_AGE);
  }

  function test_initializeV3_SetsRegistryAndFeed() public view {
    (IPriceFeedRegistryConsumer registry, ChainlinkDataStreamFeed memory priceFeed) = _domainPrice.priceRegistryData();
    assertEq(address(registry), address(_registry));
    assertEq(priceFeed._feedId, RON_USD_FEED_ID);
    assertEq(priceFeed._tokenInDecimal, _domainPrice.RON_DECIMALS());
    assertEq(priceFeed._tokenOutDecimal, _domainPrice.USD_DECIMALS());
    assertEq(priceFeed._maxAcceptableAge, MAX_ACCEPTABLE_AGE);
  }

  function test_RevertWhen_initializeV2_AfterV3() public {
    vm.expectRevert("Initializable: contract is already initialized");
    _domainPrice.initializeV2(address(0), 0);
  }

  function test_RevertWhen_initializeV3_CalledTwice() public {
    vm.expectRevert("Initializable: contract is already initialized");
    _domainPrice.initializeV3(address(_registry), RON_USD_FEED_ID, MAX_ACCEPTABLE_AGE);
  }

  function test_convertUSDToRON() public view {
    // 1 USD at 0.05 USD/RON == 20 RON
    assertEq(_domainPrice.convertUSDToRON(1 ether), 20 ether);
    assertEq(_domainPrice.convertUSDToRON(0), 0);
  }

  function test_convertRONToUSD() public view {
    // 20 RON at 0.05 USD/RON == 1 USD
    assertEq(_domainPrice.convertRONToUSD(20 ether), 1 ether);
    assertEq(_domainPrice.convertRONToUSD(0), 0);
  }

  function test_getRenewalFee_UsesRegistryPrice() public {
    // "hello" is not reserved for auction
    vm.mockCall(_auction, abi.encodeWithSelector(INSAuction.reserved.selector), abi.encode(false));
    (INSDomainPrice.UnitPrice memory basePrice, INSDomainPrice.UnitPrice memory tax) =
      _domainPrice.getRenewalFee("hello", 365 days);
    assertGt(basePrice.usd, 0);
    assertEq(basePrice.ron, _domainPrice.convertUSDToRON(basePrice.usd));
    assertEq(tax.ron, _domainPrice.convertUSDToRON(tax.usd));
  }

  function test_RevertWhen_PriceTooOld() public {
    vm.warp(block.timestamp + MAX_ACCEPTABLE_AGE + 1);
    vm.expectRevert(
      abi.encodeWithSelector(
        IPriceFeedRegistryConsumer.PriceTooOld.selector,
        RON_USD_FEED_ID,
        uint32(block.timestamp - MAX_ACCEPTABLE_AGE - 1),
        MAX_ACCEPTABLE_AGE,
        block.timestamp
      )
    );
    _domainPrice.convertUSDToRON(1 ether);
  }

  function test_RevertWhen_PriceNotAvailable() public {
    _registry.clearPrice(RON_USD_FEED_ID);
    vm.expectRevert(abi.encodeWithSelector(IPriceFeedRegistryConsumer.PriceNotAvailable.selector, RON_USD_FEED_ID));
    _domainPrice.convertUSDToRON(1 ether);
  }

  function test_setPriceFeedRegistry_Admin() public {
    MockPriceFeedRegistry newRegistry = new MockPriceFeedRegistry();
    bytes32 newFeedId = keccak256("RON/USD-v2");
    // 8 decimals price on the new registry, consumer must scale correctly
    newRegistry.setDecimals(newFeedId, 8);
    newRegistry.setPrice(newFeedId, 0.1e8, uint32(block.timestamp));

    vm.expectEmit(address(_domainPrice));
    emit PriceFeedRegistryConsumerUpgradeable.PriceFeedRegistryUpdated(address(newRegistry));
    vm.expectEmit(address(_domainPrice));
    emit PriceFeedRegistryConsumerUpgradeable.PriceFeedUpdated(newFeedId, 18, 18, 1 hours);

    vm.prank(_admin);
    _domainPrice.setPriceFeedRegistry(address(newRegistry), newFeedId, 18, 18, 1 hours);

    (IPriceFeedRegistryConsumer registry, ChainlinkDataStreamFeed memory priceFeed) = _domainPrice.priceRegistryData();
    assertEq(address(registry), address(newRegistry));
    assertEq(priceFeed._feedId, newFeedId);
    assertEq(priceFeed._maxAcceptableAge, 1 hours);
    // 1 USD at 0.1 USD/RON == 10 RON
    assertEq(_domainPrice.convertUSDToRON(1 ether), 10 ether);
  }

  function test_RevertWhen_setPriceFeedRegistry_NotAdmin() public {
    vm.expectRevert(
      abi.encodePacked(
        "AccessControl: account ",
        _stranger.toHexString(),
        " is missing role ",
        uint256(_domainPrice.DEFAULT_ADMIN_ROLE()).toHexString(32)
      )
    );
    vm.prank(_stranger);
    _domainPrice.setPriceFeedRegistry(address(_registry), RON_USD_FEED_ID, 18, 18, MAX_ACCEPTABLE_AGE);
  }
}

/// @dev Minimal IPriceFeedRegistryConsumer stub mirroring the real registry's fail-closed read semantics.
contract MockPriceFeedRegistry is IPriceFeedRegistryConsumer {
  struct StoredPrice {
    int192 price;
    uint32 observationsTimestamp;
  }

  mapping(bytes32 => StoredPrice) internal _prices;
  mapping(bytes32 => uint8) internal _decimals;

  function setPrice(bytes32 feedId, int192 price, uint32 observationsTimestamp) external {
    _prices[feedId] = StoredPrice({ price: price, observationsTimestamp: observationsTimestamp });
  }

  function setDecimals(bytes32 feedId, uint8 priceDecimal) external {
    _decimals[feedId] = priceDecimal;
  }

  function clearPrice(bytes32 feedId) external {
    delete _prices[feedId];
  }

  function getLatestPriceWithMaxAge(bytes32 feedId, uint256 maxAgeSeconds) external view returns (int192, uint8) {
    StoredPrice memory p = _prices[feedId];
    if (p.observationsTimestamp == 0) revert PriceNotAvailable(feedId);
    if (block.timestamp - uint256(p.observationsTimestamp) > maxAgeSeconds) {
      revert PriceTooOld(feedId, p.observationsTimestamp, maxAgeSeconds, block.timestamp);
    }
    return (p.price, _decimals[feedId]);
  }

  function getDecimals(bytes32 feedId) external view returns (uint8) {
    return _decimals[feedId];
  }

  function isFeedWhitelisted(bytes32 feedId) external view returns (bool) {
    return _decimals[feedId] != 0;
  }
}
