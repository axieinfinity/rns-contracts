// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { NameChecker } from "@rns-contracts/NameChecker.sol";

contract NameCheckerDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.NameCheckerParam memory param = config.sharedArguments().nameChecker;
    args = abi.encodeCall(NameChecker.initialize, (param.admin, param.minWord, param.maxWord));
  }

  function run() public virtual returns (NameChecker) {
    return NameChecker(_deployProxy(Contract.NameChecker.key()));
  }
}
