// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSCommission, RNSCommissionDeploy } from "script/contracts/RNSCommissionDeploy.s.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20240407_UpgradeControllerAndDeployRNSCommissionMainnet is Migration {
  RONRegistrarController private _controller;
  RNSCommission private _rnsCommission;

  function run() public {
    _controller = RONRegistrarController(_upgradeProxy(Contract.RONRegistrarController.key()));
    _rnsCommission = new RNSCommissionDeploy().run();
  }
}
