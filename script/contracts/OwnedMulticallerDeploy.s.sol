// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract OwnedMulticallerDeploy is RNSDeploy {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    args = abi.encode(_config.getSender());
  }

  function run() public virtual trySetUp returns (OwnedMulticaller) {
    return OwnedMulticaller(_deployImmutable(ContractKey.OwnedMulticaller));
  }
}
