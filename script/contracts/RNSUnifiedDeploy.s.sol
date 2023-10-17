// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract RNSUnifiedDeploy is RNSDeploy {
  function _defaultArguments() internal view override returns (bytes memory args) {
    Config memory config = getConfig();
    args = abi.encodeCall(
      RNSUnified.initialize,
      (config.admin, config.pauser, config.controller, config.protectedSettler, config.gracePeriod, config.baseTokenURI)
    );
  }

  function run() public virtual trySetUp returns (RNSUnified) {
    return RNSUnified(_deployProxy(ContractKey.RNSUnified));
  }
}
