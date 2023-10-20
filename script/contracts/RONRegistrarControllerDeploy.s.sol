// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RONRegistrarController } from "@rns-contracts/RONRegistrarController.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { NameChecker, NameCheckerDeploy } from "./NameCheckerDeploy.s.sol";
import { RNSDomainPrice, RNSDomainPriceDeploy } from "./RNSDomainPriceDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "./RNSReverseRegistrarDeploy.s.sol";
import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract RONRegistrarControllerDeploy is RNSDeploy {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(ContractKey.RNSUnified, new RNSUnifiedDeploy());
    _setDependencyDeployScript(ContractKey.NameChecker, new NameCheckerDeploy());
    _setDependencyDeployScript(ContractKey.RNSDomainPrice, new RNSDomainPriceDeploy());
    _setDependencyDeployScript(ContractKey.RNSReverseRegistrar, new RNSReverseRegistrarDeploy());
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
        RNSUnified(loadContractOrDeploy(ContractKey.RNSUnified)),
        NameChecker(loadContractOrDeploy(ContractKey.NameChecker)),
        RNSDomainPrice(loadContractOrDeploy(ContractKey.RNSDomainPrice)),
        RNSReverseRegistrar(loadContractOrDeploy(ContractKey.RNSReverseRegistrar))
      )
    );
  }

  function run() public virtual trySetUp returns (RONRegistrarController) {
    return RONRegistrarController(_deployProxy(ContractKey.RONRegistrarController));
  }
}
