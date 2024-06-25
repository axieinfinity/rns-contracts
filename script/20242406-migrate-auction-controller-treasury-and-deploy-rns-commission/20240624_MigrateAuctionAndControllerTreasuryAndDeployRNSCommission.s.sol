// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSCommission, RNSCommissionDeploy } from "script/contracts/RNSCommissionDeploy.s.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20240624_MigrateAuctionAndControllerTreasuryAndDeployRNSCommission is Migration {
  RNSAuction private _auction;
  RONRegistrarController private _controller;
  RNSCommission private _rnsCommission;
  address private _defaultAdmin;

  function run() public {
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _controller = RONRegistrarController(_upgradeProxy(Contract.RONRegistrarController.key()));

    _rnsCommission = new RNSCommissionDeploy().run();
    _defaultAdmin = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;

    vm.startBroadcast(_defaultAdmin);

    _controller.setTreasury(payable(address(_rnsCommission)));
    _auction.setTreasury(payable(address(_rnsCommission)));

    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    _validateSendMoneyFromSenders();
    _validateTreasuryAddress();
    _validateCommissionInfo();
  }

  function _validateTreasuryAddress() internal logFn("_validateTreasuryAddress") {
    address auctionTreasury = _auction.getTreasury();
    address controllerTreasury = _controller.getTreasury();

    assertEq(auctionTreasury, payable(address(_rnsCommission)));
    assertEq(controllerTreasury, payable(address(_rnsCommission)));
  }

  function _validateCommissionInfo() internal logFn("_validateSetCommissionInfo") {
    RNSCommission.Commission[] memory newCommission = new RNSCommission.Commission[](1);
    newCommission[0].recipient = payable(makeAddr("Random"));
    newCommission[0].ratio = 100_00;
    newCommission[0].name = "Random";

    vm.prank(_defaultAdmin);
    _rnsCommission.setCommissions(newCommission);

    assertEq(_rnsCommission.getCommissions().length, 1);
    assertEq(_rnsCommission.getCommissions()[0].recipient, newCommission[0].recipient);
  }

  function _validateSendMoneyFromSenders() internal logFn("_validateSendMoneyFailFromSenders") {
    vm.prank(address(_auction));
    address(_rnsCommission).call{ value: 100 ether }("");

    vm.prank(address(_controller));
    address(_rnsCommission).call{ value: 100 ether }("");

    assertEq(address(_rnsCommission).balance, 0 ether);

    vm.prank(_defaultAdmin);
    address(_rnsCommission).call{ value: 100 ether }("");

    assertEq(address(_rnsCommission).balance, 100 ether);
  }
}
