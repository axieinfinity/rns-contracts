// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract OwnedMulticallerDeploy is RNSDeploy {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    args = abi.encode(config.admin);
  }

  function run() public virtual trySetUp returns (OwnedMulticaller) {
    return OwnedMulticaller(_deployImmutable(ContractKey.OwnedMulticaller));
  }
}
