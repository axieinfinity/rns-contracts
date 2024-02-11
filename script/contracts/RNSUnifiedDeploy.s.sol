// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";

contract RNSUnifiedDeploy is Migration {
  function _defaultArguments() internal view override returns (bytes memory args) {
    ISharedArgument.RNSUnifiedParam memory param = config.sharedArguments().rnsUnified;
    args = abi.encodeCall(
      RNSUnified.initialize,
      (param.admin, param.pauser, param.controller, param.protectedSettler, param.gracePeriod, param.baseTokenURI)
    );
  }

  function run() public virtual returns (RNSUnified) {
    return RNSUnified(_deployProxy(Contract.RNSUnified.key()));
  }
}
