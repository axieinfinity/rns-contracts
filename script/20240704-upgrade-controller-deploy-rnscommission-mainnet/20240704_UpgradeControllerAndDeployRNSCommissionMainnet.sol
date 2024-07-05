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
  RNSAuction _auction;

  function run() public {
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _controller = RONRegistrarController(_upgradeProxy(Contract.RONRegistrarController.key()));
    _rnsCommission = new RNSCommissionDeploy().run();
  }

  function _postCheck() internal override {
    _validateSendMoneyFromSenders();
    _validateCommissionInfo();
    _validateSendersAddress();
  }

  function _validateCommissionInfo() internal logFn("_validateSetCommissionInfo") {
    assertEq(_rnsCommission.getCommissions().length, 2);

    assertEq(_rnsCommission.getCommissions()[0].recipient, payable(0xFf43f5Ef28EcB7c1f219751fc793deB40ef07A53));
    assertEq(_rnsCommission.getCommissions()[1].recipient, payable(0x22cEfc91E9b7c0f3890eBf9527EA89053490694e));

    assertEq(_rnsCommission.getCommissions()[0].ratio, 70_00);
    assertEq(_rnsCommission.getCommissions()[1].ratio, 30_00);

    assertEq(_rnsCommission.getCommissions()[0].name, "Sky Mavis");
    assertEq(_rnsCommission.getCommissions()[1].name, "Ronin");
  }

  function _validateSendMoneyFromSenders() internal logFn("_validateSendMoneyFromSenders") {
    vm.deal(address(_auction), 100 ether);
    vm.prank(address(_auction));
    address(_rnsCommission).call{ value: 100 ether }("");

    vm.deal(address(_controller), 100 ether);
    vm.prank(address(_controller));
    address(_rnsCommission).call{ value: 100 ether }("");

    assertEq(address(_rnsCommission).balance, 0 ether);

    address randomAddr = makeAddr("random address");
    vm.deal(address(randomAddr), 100 ether);
    vm.prank(randomAddr);
    address(_rnsCommission).call{ value: 100 ether }("");

    assertEq(address(_rnsCommission).balance, 100 ether);
  }

  function _validateSendersAddress() internal logFn("_validateSendersAddress") {
    bytes32 SENDER_ROLE = keccak256("SENDER_ROLE");

    require(_rnsCommission.hasRole(SENDER_ROLE, address(_auction)));
    require(_rnsCommission.hasRole(SENDER_ROLE, address(_controller)));
  }
}
