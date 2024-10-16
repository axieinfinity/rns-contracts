// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration, ISharedArgument } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { PublicResolver } from "@rns-contracts/resolvers/PublicResolver.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";

contract PublicResolverDeploy is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
    _setDependencyDeployScript(Contract.RNSReverseRegistrar.key(), new RNSReverseRegistrarDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.PublicResolverParam memory param = config.sharedArguments().publicResolver;
    args = abi.encodeCall(
      PublicResolver.initialize,
      (
        address(param.rnsUnified) == address(0x0)
          ? RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key()))
          : param.rnsUnified,
        address(param.rnsReverseRegistrar) == address(0x0)
          ? RNSReverseRegistrar(loadContractOrDeploy(Contract.RNSReverseRegistrar.key()))
          : param.rnsReverseRegistrar
      )
    );
  }

  function run() public virtual returns (PublicResolver) {
    return PublicResolver(_deployProxy(Contract.PublicResolver.key()));
  }
}
