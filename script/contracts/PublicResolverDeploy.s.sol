// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { PublicResolver } from "@rns-contracts/resolvers/PublicResolver.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";
import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract PublicResolverDeploy is BaseRNSMigration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
    _setDependencyDeployScript(Contract.RNSReverseRegistrar.key(), new RNSReverseRegistrarDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    args = abi.encodeCall(
      PublicResolver.initialize,
      (
        RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())),
        RNSReverseRegistrar(loadContractOrDeploy(Contract.RNSReverseRegistrar.key()))
      )
    );
  }

  function run() public virtual returns (PublicResolver) {
    return PublicResolver(_deployProxy(Contract.PublicResolver.key()));
  }
}
