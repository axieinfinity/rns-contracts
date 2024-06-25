// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
  ITransparentUpgradeableProxy,
  TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { LibProxy } from "@fdk/libraries/LibProxy.sol";
import { NameChecker } from "@rns-contracts/NameChecker.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20231114_DeployNameCheckerLogic is Migration {
  using LibProxy for address payable;

  function run() public {
    address newLogic = _deployLogic(Contract.NameChecker.key());

    NameChecker currentNameChecker = NameChecker(loadContract(Contract.NameChecker.key()));
    assertTrue(currentNameChecker.forbidden("hell"), "hell");
    assertTrue(currentNameChecker.forbidden("hellscream"), "hellscream");
    assertTrue(currentNameChecker.forbidden("hell123"), "hell123");

    address proxyAdmin = LibProxy.getProxyAdmin(payable(address(currentNameChecker)));
    vm.prank(ProxyAdmin(proxyAdmin).owner());
    ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(address(currentNameChecker)), newLogic);

    assertTrue(currentNameChecker.forbidden("hell"), "hell");
    assertFalse(currentNameChecker.forbidden("hellscream"), "hellscream");
    assertTrue(currentNameChecker.forbidden("hell123"), "hell123");
    assertTrue(currentNameChecker.forbidden("heo123hell"), "heo123hell");
  }
}
