// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";

contract OwnedMulticallerDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.OwnedMulticallerParam memory param = config.sharedArguments().ownedMulticaller;
    args = abi.encode(param.admin);
  }

  function run() public virtual returns (OwnedMulticaller) {
    return OwnedMulticaller(_deployImmutable(Contract.OwnedMulticaller.key()));
  }
}
