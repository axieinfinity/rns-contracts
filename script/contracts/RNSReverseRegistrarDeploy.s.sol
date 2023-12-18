// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSReverseRegistrar } from "@rns-contracts/RNSReverseRegistrar.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";

contract RNSReverseRegistrarDeploy is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.SharedParameter memory param = config.sharedArguments();
    address[] memory operators = new address[](1);
    operators[0] = param.operator;
    args = abi.encodeCall(
      RNSReverseRegistrar.initialize, (param.admin, RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())))
    );
  }

  function run() public virtual returns (RNSReverseRegistrar) {
    return RNSReverseRegistrar(_deployProxy(Contract.RNSReverseRegistrar.key()));
  }
}
