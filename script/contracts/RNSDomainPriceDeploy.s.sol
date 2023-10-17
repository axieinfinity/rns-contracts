// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { RNSAuction, RNSAuctionDeploy } from "./RNSAuctionDeploy.s.sol";
import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract RNSDomainPriceDeploy is RNSDeploy {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(ContractKey.RNSAuction, new RNSAuctionDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    address[] memory operators = new address[](1);
    operators[0] = config.operator;
    args = abi.encodeCall(
      RNSDomainPrice.initialize,
      (
        config.admin,
        operators,
        config.renewalFees,
        config.taxRatio,
        config.domainPriceScaleRule,
        config.pyth,
        RNSAuction(loadContractOrDeploy(ContractKey.RNSAuction)),
        config.maxAcceptableAge,
        config.pythIdForRONUSD
      )
    );
  }

  function run() public virtual trySetUp returns (RNSDomainPrice) {
    return RNSDomainPrice(_deployProxy(ContractKey.RNSDomainPrice));
  }
}
