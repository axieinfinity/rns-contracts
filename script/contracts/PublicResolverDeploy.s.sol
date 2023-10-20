// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { PublicResolver } from "@rns-contracts/resolvers/PublicResolver.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract PublicResolverDeploy is RNSDeploy {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(ContractKey.RNSUnified, new RNSUnifiedDeploy());
    _setDependencyDeployScript(ContractKey.RNSReverseRegistrar, new RNSReverseRegistrarDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    args = abi.encodeCall(
      PublicResolver.initialize,
      (
        RNSUnified(loadContractOrDeploy(ContractKey.RNSUnified)),
        RNSReverseRegistrar(loadContractOrDeploy(ContractKey.RNSReverseRegistrar))
      )
    );
  }

  function run() public virtual trySetUp returns (PublicResolver) {
    return PublicResolver(_deployProxy(ContractKey.PublicResolver));
  }
}
