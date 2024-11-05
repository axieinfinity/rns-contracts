// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSCommission, RNSCommissionDeploy } from "script/contracts/RNSCommissionDeploy.s.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20241105_UpgradeRNSCommissionMainnet is Migration {
  RONRegistrarController private _controller;
  RNSCommission private _rnsCommission;
  RNSAuction _auction;

  function run() public {
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _controller = RONRegistrarController(loadContract(Contract.RONRegistrarController.key()));
    _rnsCommission = RNSCommission(_upgradeProxy(Contract.RNSCommission.key()));
  }

  function _postCheck() internal override {
    _validateCommissionInfo();
    _validateSendersAddress();
    _validateSendMoneyFromSenders_NonZeroRonAmount();
    _validateSendMoneyFromSenders_ZeroRonAmount();
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

  function _validateSendMoneyFromSenders_NonZeroRonAmount()
    internal
    logFn("_validateSendMoneyFromSenders_NonZeroRonAmount")
  {
    bool sent;
    vm.deal(address(_auction), 100 ether);
    vm.prank(address(_auction));
    (sent,) = address(_rnsCommission).call{ value: 100 ether }("");
    assertTrue(sent);

    vm.deal(address(_controller), 100 ether);
    vm.prank(address(_controller));
    (sent,) = address(_rnsCommission).call{ value: 100 ether }("");
    assertTrue(sent);

    assertEq(address(_rnsCommission).balance, 0 ether);

    address randomAddr = makeAddr("random address");
    vm.deal(address(randomAddr), 100 ether);
    vm.prank(randomAddr);
    (sent,) = address(_rnsCommission).call{ value: 100 ether }("");
    assertTrue(sent);

    assertEq(address(_rnsCommission).balance, 100 ether);
  }

  function _validateSendMoneyFromSenders_ZeroRonAmount() internal logFn("_validateSendMoneyFromSenders_ZeroRonAmount") {
    bool sent;
    uint256 balanceBefore = address(_rnsCommission).balance;

    vm.prank(address(_auction));
    (sent,) = address(_rnsCommission).call{ value: 0 }("");
    assertTrue(sent);

    vm.prank(address(_controller));
    (sent,) = address(_rnsCommission).call{ value: 0 }("");
    assertTrue(sent);

    assertEq(address(_rnsCommission).balance, balanceBefore);
  }

  function _validateSendersAddress() internal logFn("_validateSendersAddress") {
    bytes32 SENDER_ROLE = keccak256("SENDER_ROLE");

    require(_rnsCommission.hasRole(SENDER_ROLE, address(_auction)));
    require(_rnsCommission.hasRole(SENDER_ROLE, address(_controller)));
  }
}
