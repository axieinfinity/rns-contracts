// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseGeneralConfig } from "foundry-deployment-kit/BaseGeneralConfig.sol";
import { Contract } from "./utils/Contract.sol";

contract GeneralConfig is BaseGeneralConfig {
  constructor() BaseGeneralConfig("", "deployments/") { }

  function _setUpContracts() internal virtual override {
    _mapContractName(Contract.RNSUnified);
    _mapContractName(Contract.RNSAuction);
    _mapContractName(Contract.NameChecker);
    _mapContractName(Contract.RNSOperation);
    _mapContractName(Contract.RNSDomainPrice);
    _mapContractName(Contract.PublicResolver);
    _mapContractName(Contract.OwnedMulticaller);
    _mapContractName(Contract.RNSReverseRegistrar);
    _mapContractName(Contract.RONRegistrarController);
    _mapContractName(Contract.RNSCommission);
  }

  function _mapContractName(Contract contractEnum) internal {
    _contractNameMap[contractEnum.key()] = contractEnum.name();
  }
}
