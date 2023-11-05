// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSReverseRegistrar } from "@rns-contracts/RNSReverseRegistrar.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";

import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract RNSReverseRegistrarDeploy is BaseRNSMigration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    address[] memory operators = new address[](1);
    operators[0] = config.operator;
    args = abi.encodeCall(
      RNSReverseRegistrar.initialize, (config.admin, RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())))
    );
  }

  function run() public virtual returns (RNSReverseRegistrar) {
    return RNSReverseRegistrar(_deployProxy(Contract.RNSReverseRegistrar.key()));
  }
}
