// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration, ISharedArgument } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSOperation } from "@rns-contracts/utils/RNSOperation.sol";

contract RNSOperationDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.RNSOperationParam memory param = config.sharedArguments().rnsOperation;
    args = abi.encode(
      param.rnsUnified == address(0x0) ? loadContract(Contract.RNSUnified.key()) : param.rnsUnified,
      param.publicResolver == address(0x0) ? loadContract(Contract.PublicResolver.key()) : param.publicResolver,
      param.rnsAuction == address(0x0) ? loadContract(Contract.RNSAuction.key()) : param.rnsAuction,
      param.rnsDomainPrice == address(0x0) ? loadContract(Contract.RNSDomainPrice.key()) : param.rnsDomainPrice
    );
  }

  function run() public virtual returns (RNSOperation) {
    return RNSOperation(_deployImmutable(Contract.RNSOperation.key()));
  }
}
