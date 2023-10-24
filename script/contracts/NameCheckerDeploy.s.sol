// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { NameChecker } from "@rns-contracts/NameChecker.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract NameCheckerDeploy is RNSDeploy {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    args = abi.encodeCall(NameChecker.initialize, (config.admin, config.minWord, config.maxWord));
  }

  function run() public virtual trySetUp returns (NameChecker) {
    return NameChecker(_deployProxy(ContractKey.NameChecker));
  }
}
