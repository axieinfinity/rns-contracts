// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { BaseDeploy, ContractKey } from "foundry-deployment-kit/BaseDeploy.s.sol";
import { RNSDeploy } from "../RNSDeploy.s.sol";

contract RNSAuctionDeploy is RNSDeploy {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(ContractKey.RNSUnified, new RNSUnifiedDeploy());
  }

  function _defaultArguments() internal virtual override returns (bytes memory args) {
    Config memory config = getConfig();
    address[] memory operators = new address[](1);
    operators[0] = config.operator;
    args = abi.encodeCall(
      RNSAuction.initialize,
      (
        config.admin,
        operators,
        RNSUnified(loadContractOrDeploy(ContractKey.RNSUnified)),
        config.treasury,
        config.bidGapRatio
      )
    );
  }

  function run() public virtual trySetUp returns (RNSAuction) {
    return RNSAuction(_deployProxy(ContractKey.RNSAuction));
  }
}
