// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RONRegistrarController } from "@rns-contracts/RONRegistrarController.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { NameChecker, NameCheckerDeploy } from "./NameCheckerDeploy.s.sol";
import { RNSDomainPrice, RNSDomainPriceDeploy } from "./RNSDomainPriceDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";

contract RONRegistrarControllerDeploy is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
    _setDependencyDeployScript(Contract.NameChecker.key(), new NameCheckerDeploy());
    _setDependencyDeployScript(Contract.RNSDomainPrice.key(), new RNSDomainPriceDeploy());
    _setDependencyDeployScript(Contract.RNSReverseRegistrar.key(), new RNSReverseRegistrarDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.RONRegistrarControllerParam memory param = config.sharedArguments().ronRegistrarController;
    args = abi.encodeCall(
      RONRegistrarController.initialize,
      (
        param.admin,
        param.pauser,
        param.treasury,
        param.maxAcceptableAge,
        param.minCommitmentAge,
        param.minRegistrationDuration,
        address(param.rnsUnified) == address(0x0)
          ? RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key()))
          : param.rnsUnified,
        address(param.nameChecker) == address(0x0)
          ? NameChecker(loadContractOrDeploy(Contract.NameChecker.key()))
          : param.nameChecker,
        address(param.rnsDomainPrice) == address(0x0)
          ? RNSDomainPrice(loadContractOrDeploy(Contract.RNSDomainPrice.key()))
          : param.rnsDomainPrice,
        address(param.rnsReverseRegistrar) == address(0x0)
          ? RNSReverseRegistrar(loadContractOrDeploy(Contract.RNSReverseRegistrar.key()))
          : param.rnsReverseRegistrar
      )
    );
  }

  function run() public virtual returns (RONRegistrarController) {
    return RONRegistrarController(_deployProxy(Contract.RONRegistrarController.key()));
  }
}
