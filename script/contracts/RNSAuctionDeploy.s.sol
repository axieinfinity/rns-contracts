// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";

contract RNSAuctionDeploy is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.SharedParameter memory param = config.sharedArguments();
    args = abi.encodeCall(
      RNSAuction.initialize,
      (
        param.admin,
        param.auctionOperators,
        RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())),
        param.treasury,
        param.bidGapRatio
      )
    );
  }

  function run() public virtual returns (RNSAuction) {
    return RNSAuction(_deployProxy(Contract.RNSAuction.key()));
  }
}
