// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { RNSOperation } from "@rns-contracts/utils/RNSOperation.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract RNSOperationDeploy is RNSDeploy {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    args = abi.encode(
      _config.getAddressFromCurrentNetwork(ContractKey.RNSUnified),
      _config.getAddressFromCurrentNetwork(ContractKey.PublicResolver),
      _config.getAddressFromCurrentNetwork(ContractKey.RNSAuction)
    );
  }

  function run() public virtual trySetUp returns (RNSOperation) {
    return RNSOperation(_deployImmutable(ContractKey.RNSOperation));
  }
}
