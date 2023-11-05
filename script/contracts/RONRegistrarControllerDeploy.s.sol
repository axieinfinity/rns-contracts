// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RONRegistrarController } from "@rns-contracts/RONRegistrarController.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { NameChecker, NameCheckerDeploy } from "./NameCheckerDeploy.s.sol";
import { RNSDomainPrice, RNSDomainPriceDeploy } from "./RNSDomainPriceDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";
import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract RONRegistrarControllerDeploy is BaseRNSMigration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
    _setDependencyDeployScript(Contract.NameChecker.key(), new NameCheckerDeploy());
    _setDependencyDeployScript(Contract.RNSDomainPrice.key(), new RNSDomainPriceDeploy());
    _setDependencyDeployScript(Contract.RNSReverseRegistrar.key(), new RNSReverseRegistrarDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    address[] memory operators = new address[](1);
    operators[0] = config.operator;
    args = abi.encodeCall(
      RONRegistrarController.initialize,
      (
        config.admin,
        config.pauser,
        config.treasury,
        config.maxAcceptableAge,
        config.minCommitmentAge,
        config.minRegistrationDuration,
        RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())),
        NameChecker(loadContractOrDeploy(Contract.NameChecker.key())),
        RNSDomainPrice(loadContractOrDeploy(Contract.RNSDomainPrice.key())),
        RNSReverseRegistrar(loadContractOrDeploy(Contract.RNSReverseRegistrar.key()))
      )
    );
  }

  function run() public virtual returns (RONRegistrarController) {
    return RONRegistrarController(_deployProxy(Contract.RONRegistrarController.key()));
  }
}
