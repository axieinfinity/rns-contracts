// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { NameChecker } from "@rns-contracts/NameChecker.sol";
import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract NameCheckerDeploy is BaseRNSMigration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    args = abi.encodeCall(NameChecker.initialize, (config.admin, config.minWord, config.maxWord));
  }

  function run() public virtual returns (NameChecker) {
    return NameChecker(_deployProxy(Contract.NameChecker.key()));
  }
}
