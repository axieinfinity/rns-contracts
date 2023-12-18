// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSOperation } from "@rns-contracts/utils/RNSOperation.sol";

contract RNSOperationDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    args = abi.encode(
      config.getAddressFromCurrentNetwork(Contract.RNSUnified.key()),
      config.getAddressFromCurrentNetwork(Contract.PublicResolver.key()),
      config.getAddressFromCurrentNetwork(Contract.RNSAuction.key()),
      config.getAddressFromCurrentNetwork(Contract.RNSDomainPrice.key())
    );
  }

  function run() public virtual returns (RNSOperation) {
    return RNSOperation(_deployImmutable(Contract.RNSOperation.key()));
  }
}
