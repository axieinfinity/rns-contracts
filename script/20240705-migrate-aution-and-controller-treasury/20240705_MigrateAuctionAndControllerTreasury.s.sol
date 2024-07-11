// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { RNSCommission, RNSCommissionDeploy } from "script/contracts/RNSCommissionDeploy.s.sol";

contract Migration__20240507_MigrateAuctionAndControllerTreasuryMainnet is Migration {
  RONRegistrarController private _controller;
  RNSAuction private _auction;
  RNSCommission private _commission;
  address private _currentAdmin;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function run() public {
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _controller = RONRegistrarController(loadContract(Contract.RONRegistrarController.key()));
    _commission = RNSCommission(loadContract(Contract.RNSCommission.key()));
    _currentAdmin = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;

    vm.startBroadcast(_currentAdmin);
    _auction.setTreasury(payable(address(_commission)));
    _controller.setTreasury(payable(address(_commission)));
    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    _validateTreasuryAddress();
    _validateSendersAddress();
    _validateSendMoneyToCommission();
  }

  function _validateTreasuryAddress() internal logFn("_validateTreasuryAddress") {
    assertEq(_auction.getTreasury(), address(_commission));
    assertEq(_controller.getTreasury(), address(_commission));
  }

  function _validateSendersAddress() internal logFn("_validateSendersAddress") {
    bytes32 SENDER_ROLE = keccak256("SENDER_ROLE");

    require(_commission.hasRole(SENDER_ROLE, address(_auction)));
    require(_commission.hasRole(SENDER_ROLE, address(_controller)));
  }

  function _validateSendMoneyToCommission() internal logFn("_validateSendMoneyToCommission") {
    vm.deal(address(_auction), 100 ether);
    vm.prank(address(_auction));
    address(_commission).call{ value: 100 ether }("");

    vm.deal(address(_controller), 100 ether);
    vm.prank(address(_controller));
    address(_commission).call{ value: 100 ether }("");

    assertEq(address(_commission).balance, 0 ether);

    address randomAddr = makeAddr("random address");
    vm.deal(address(randomAddr), 100 ether);
    vm.prank(randomAddr);
    address(_commission).call{ value: 100 ether }("");

    assertEq(address(_commission).balance, 100 ether);
  }
}
