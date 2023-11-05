// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { RNSUnified, RNSUnifiedDeploy } from "./RNSUnifiedDeploy.s.sol";
import { Contract, BaseRNSMigration } from "../BaseRNSMigration.s.sol";

contract RNSAuctionDeploy is BaseRNSMigration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.RNSUnified.key(), new RNSUnifiedDeploy());
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
        RNSUnified(loadContractOrDeploy(Contract.RNSUnified.key())),
        config.treasury,
        config.bidGapRatio
      )
    );
  }

  function run() public virtual returns (RNSAuction) {
    return RNSAuction(_deployProxy(Contract.RNSAuction.key()));
  }
}
