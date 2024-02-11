// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { RNSAuction, RNSAuctionDeploy } from "./RNSAuctionDeploy.s.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";

contract RNSDomainPriceDeploy is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSAuction.key(), new RNSAuctionDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    ISharedArgument.SharedParameter memory param = config.sharedArguments();
    args = abi.encodeCall(
      RNSDomainPrice.initialize,
      (
        param.admin,
        param.domainPriceOperators,
        param.renewalFees,
        param.taxRatio,
        param.domainPriceScaleRule,
        param.pyth,
        RNSAuction(loadContractOrDeploy(Contract.RNSAuction.key())),
        param.maxAcceptableAge,
        param.pythIdForRONUSD
      )
    );
  }

  function run() public virtual returns (RNSDomainPrice) {
    return RNSDomainPrice(_deployProxy(Contract.RNSDomainPrice.key()));
  }
}
