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
    ISharedArgument.RNSAuctionParam memory param = config.sharedArguments().rnsAuction;
    args = abi.encodeCall(
      RNSAuction.initialize,
      (
        param.admin,
        param.auctionOperators,
        address(param.rnsUnified) == address(0x0)
          ? RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key()))
          : param.rnsUnified,
        param.treasury,
        param.bidGapRatio
      )
    );
  }

  function run() public virtual returns (RNSAuction) {
    return RNSAuction(_deployProxy(Contract.RNSAuction.key()));
  }
}
