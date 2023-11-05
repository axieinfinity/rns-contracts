// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { RNSAuction, RNSAuctionDeploy } from "./RNSAuctionDeploy.s.sol";

import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract RNSDomainPriceDeploy is BaseRNSMigration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSAuction.key(), new RNSAuctionDeploy());
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
        RNSAuction(loadContractOrDeploy(Contract.RNSAuction.key())),
        config.maxAcceptableAge,
        config.pythIdForRONUSD
      )
    );
  }

  function run() public virtual returns (RNSDomainPrice) {
    return RNSDomainPrice(_deployProxy(Contract.RNSDomainPrice.key()));
  }
}
