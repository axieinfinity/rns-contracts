// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSCommission } from "@rns-contracts/RNSCommission.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RONRegistrarController, RONRegistrarControllerDeploy } from "./RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSAuction, RNSAuctionDeploy } from "./RNSAuctionDeploy.s.sol";

contract RNSCommissionDeploy is Migration {
  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.RNSCommissionParam memory param = config.sharedArguments().rnsCommission;
    address[] memory allowedSenders;
    allowedSenders = new address[](2);
    allowedSenders[0] = param.allowedSenders[0] == address(0)
      ? address(RNSAuction(loadContract(Contract.RNSAuction.key())))
      : param.allowedSenders[0];
    allowedSenders[1] = param.allowedSenders[1] == address(0)
      ? address(RONRegistrarController(loadContract(Contract.RONRegistrarController.key())))
      : param.allowedSenders[1];

    args = abi.encodeCall(RNSCommission.initialize, (param.admin, param.treasuryCommission, allowedSenders));
  }

  function run() public virtual returns (RNSCommission) {
    return RNSCommission(_deployProxy(Contract.RNSCommission.key()));
  }
}
