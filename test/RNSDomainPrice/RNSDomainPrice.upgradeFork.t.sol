// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, console2 } from "forge-std/Test.sol";
import { LibProxy } from "@fdk/libraries/LibProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
  ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { RNSDomainPrice, INSDomainPrice } from "src/RNSDomainPrice.sol";
import { IRONRegistrarController } from "src/interfaces/IRONRegistrarController.sol";
import { IPriceFeedRegistryConsumer } from "src/interfaces/IPriceFeedRegistryConsumer.sol";
import { ChainlinkDataStreamFeed } from "src/libraries/LibChainlinkDataStreamFeed.sol";

/**
 * @dev Simulates the 20260904 RNSDomainPrice upgrade (deploy logic + `ProxyAdmin.upgradeAndCall` with `initializeV3`)
 * on a fork of the live networks. Opt-in because it needs RPC access:
 *
 *   RUN_FORK_TESTS=true forge test --match-path test/RNSDomainPrice/RNSDomainPrice.upgradeFork.t.sol -vv \
 *     --fork-url https://api.roninchain.com/rpc --fork-block-number 60525700 \
 *     --compute-units-per-second 15 --fork-retries 20 --fork-retry-backoff 8000
 *
 * (`--fork-url` is only there to enable the rate-limit flags; the public Ronin RPCs throttle forge's state fetches.)
 */
contract RNSDomainPriceUpgradeForkTest is Test {
  function setUp() public {
    vm.skip(!vm.envOr("RUN_FORK_TESTS", false));
  }

  function test_mainnet() public {
    _run(
      "https://api.roninchain.com/rpc",
      60525700,
      "ronin-mainnet",
      0x7D21f62Da4ab252159bD865F3E3144B1D94E544D,
      0x0003892129eeb6c0d5d33bd734b0ca0d409130f5984d6051452a777f103ce628
    );
  }

  function test_testnet() public {
    _run(
      "https://saigon-testnet.roninchain.com/rpc",
      0,
      "ronin-testnet",
      0xd3Aa8f60553cE9Cb9FDE7dDC3F796D15dc8B87B3,
      0x000348db760241ba2b0c3a81e6da756208d658ac20ebd82e291c2f08d1d33f96
    );
  }

  function _addr(string memory net, string memory name) internal view returns (address) {
    return vm.parseJsonAddress(vm.readFile(string.concat("deployments/", net, "/", name, ".json")), ".address");
  }

  struct Ctx {
    address payable proxy;
    address controller;
    address proxyAdmin;
    address owner;
    address registry;
    bytes32 feedId;
    address logic;
    uint256 adminCount;
    address admin0;
    INSDomainPrice.RenewalFee[] feesBefore;
  }

  Ctx internal c;

  function _run(string memory rpc, uint256 blockNumber, string memory net, address registry, bytes32 feedId) internal {
    if (blockNumber == 0) vm.createSelectFork(rpc);
    else vm.createSelectFork(rpc, blockNumber);
    c.proxy = payable(_addr(net, "RNSDomainPriceProxy"));
    c.controller = _addr(net, "RONRegistrarControllerProxy");
    c.proxyAdmin = LibProxy.getProxyAdmin(c.proxy);
    c.owner = ProxyAdmin(c.proxyAdmin).owner();
    c.registry = registry;
    c.feedId = feedId;
    _snapshot();
    _upgrade();
    _checkFeed();
    _checkPrices();
    _checkState();
  }

  function _snapshot() internal {
    RNSDomainPrice dp = RNSDomainPrice(c.proxy);
    c.adminCount = dp.getRoleMemberCount(0x00);
    c.admin0 = dp.getRoleMember(0x00, 0);
    INSDomainPrice.RenewalFee[] memory fees = dp.getRenewalFeeByLengths();
    for (uint256 i; i < fees.length; ++i) {
      c.feesBefore.push(fees[i]);
    }
    assertEq(uint256(vm.load(c.proxy, 0)) & 0xff, 2, "expected _initialized == 2");
    // before: price read reverts (deprecated aggregator)
    vm.expectRevert();
    dp.convertUSDToRON(1e18);
  }

  function _upgrade() internal {
    c.logic = address(new RNSDomainPrice());
    bytes memory data = abi.encodeCall(RNSDomainPrice.initializeV3, (c.registry, c.feedId, 24 hours));
    console2.log("proxyAdmin", c.proxyAdmin, "owner", c.owner);
    console2.log("upgradeAndCall calldata:");
    console2.logBytes(abi.encodeCall(ProxyAdmin.upgradeAndCall, (ITransparentUpgradeableProxy(c.proxy), c.logic, data)));
    vm.prank(c.owner);
    ProxyAdmin(c.proxyAdmin).upgradeAndCall(ITransparentUpgradeableProxy(c.proxy), c.logic, data);
    assertEq(LibProxy.getProxyImplementation(c.proxy), c.logic, "impl not updated");
    assertEq(uint256(vm.load(c.proxy, 0)) & 0xff, 3, "_initialized != 3");
  }

  function _checkFeed() internal view {
    (IPriceFeedRegistryConsumer r, ChainlinkDataStreamFeed memory f) = RNSDomainPrice(c.proxy).priceRegistryData();
    assertEq(address(r), c.registry);
    assertEq(f._feedId, c.feedId);
    assertEq(f._tokenInDecimal, 18);
    assertEq(f._tokenOutDecimal, 18);
    assertEq(f._maxAcceptableAge, 24 hours);
  }

  function _checkPrices() internal view {
    RNSDomainPrice dp = RNSDomainPrice(c.proxy);
    (int192 price, uint8 dec) = IPriceFeedRegistryConsumer(c.registry).getLatestPriceWithMaxAge(c.feedId, 24 hours);
    uint256 ronPerUsd = dp.convertUSDToRON(1e18);
    assertApproxEqRel(ronPerUsd, 10 ** (18 + dec) / uint256(uint192(price)), 1e15, "USD->RON");
    assertApproxEqRel(dp.convertRONToUSD(1e18), uint256(uint192(price)) * 1e18 / 10 ** dec, 1e15, "RON->USD");
    console2.log("RON/USD price", uint256(uint192(price)), "1 USD in RON wei", ronPerUsd);
    (uint256 usd, uint256 ron) = IRONRegistrarController(c.controller).rentPrice("tudo-hihi-haha", 365 days);
    assertGt(usd, 0);
    assertApproxEqRel(ron, usd * ronPerUsd / 1e18, 1e15, "rentPrice");
    console2.log("rentPrice usd", usd, "ron", ron);
  }

  function _checkState() internal {
    RNSDomainPrice dp = RNSDomainPrice(c.proxy);
    assertEq(dp.getRoleMemberCount(0x00), c.adminCount);
    assertEq(dp.getRoleMember(0x00, 0), c.admin0);
    INSDomainPrice.RenewalFee[] memory feesAfter = dp.getRenewalFeeByLengths();
    assertEq(feesAfter.length, c.feesBefore.length);
    for (uint256 i; i < feesAfter.length; ++i) {
      assertEq(feesAfter[i].labelLength, c.feesBefore[i].labelLength);
      assertEq(feesAfter[i].fee, c.feesBefore[i].fee);
    }
    vm.expectRevert("Initializable: contract is already initialized");
    dp.initializeV3(c.registry, c.feedId, 24 hours);
    vm.expectRevert("Initializable: contract is already initialized");
    dp.initializeV2(address(0), 0);
    vm.expectRevert();
    dp.setPriceFeedRegistry(c.registry, c.feedId, 18, 18, 1 hours);
    vm.prank(c.admin0);
    dp.setPriceFeedRegistry(c.registry, c.feedId, 18, 18, 1 hours);
    (, ChainlinkDataStreamFeed memory f) = dp.priceRegistryData();
    assertEq(f._maxAcceptableAge, 1 hours);
  }
}
