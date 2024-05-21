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
    ISharedArgument.RNSReverseRegistrarParam memory param = config.sharedArguments().rnsReverseRegistrar;
    args = abi.encodeCall(
      RNSReverseRegistrar.initialize,
      (
        param.admin,
        address(param.rnsUnified) == address(0x0)
          ? RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key()))
          : param.rnsUnified
      )
    );
  }

  function run() public virtual returns (RNSReverseRegistrar) {
    return RNSReverseRegistrar(_deployProxy(Contract.RNSReverseRegistrar.key()));
  }
}
