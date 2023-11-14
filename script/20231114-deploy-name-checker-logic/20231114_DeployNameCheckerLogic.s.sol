// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
  ITransparentUpgradeableProxy,
  TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { NameChecker } from "@rns-contracts/NameChecker.sol";
import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";

contract Migration__20231114_DeployNameCheckerLogic is RNSDeploy {
  function run() public trySetUp {
    address newLogic = _deployLogic(ContractKey.NameChecker);

    NameChecker currentNameChecker = NameChecker(_config.getAddressFromCurrentNetwork(ContractKey.NameChecker));
    assertTrue(currentNameChecker.forbidden("hell"));
    assertTrue(currentNameChecker.forbidden("hellscream"));

    address proxyAdmin = _getProxyAdmin(address(currentNameChecker));
    vm.prank(ProxyAdmin(proxyAdmin).owner());
    ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(address(currentNameChecker)), newLogic);

    assertTrue(currentNameChecker.forbidden("hell"));
    assertFalse(currentNameChecker.forbidden("hellscream"));
  }
}
