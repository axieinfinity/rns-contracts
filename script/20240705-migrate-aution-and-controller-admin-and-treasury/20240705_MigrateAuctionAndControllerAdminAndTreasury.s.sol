// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { RNSCommission, RNSCommissionDeploy } from "script/contracts/RNSCommissionDeploy.s.sol";

contract Migration__20240507_MigrateAuctionAndControllerAdminAndTreasuryMainnet is Migration {
  RONRegistrarController private _controller;
  RNSAuction private _auction;
  RNSCommission private _commission;
  address private _currentAdmin;
  address private _nextAdmin;
  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  function run() public {
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _controller = RONRegistrarController(loadContract(Contract.RONRegistrarController.key()));
    _commission = RNSCommission(loadContract(Contract.RNSCommission.key()));
    _currentAdmin = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
    _nextAdmin = 0x9D05D1F5b0424F8fDE534BC196FFB6Dd211D902a;

    vm.startBroadcast(_currentAdmin);
    _auction.setTreasury(payable(address(_commission)));
    _controller.setTreasury(payable(address(_commission)));

    _auction.grantRole(DEFAULT_ADMIN_ROLE, _nextAdmin);
    _controller.grantRole(DEFAULT_ADMIN_ROLE, _nextAdmin);

    _auction.revokeRole(DEFAULT_ADMIN_ROLE, _currentAdmin);
    _controller.revokeRole(DEFAULT_ADMIN_ROLE, _currentAdmin);
    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    _validateTreasuryAddress();
    _validateNewAdmin();
    _validatePrevAdminIsRevoked();
    _validateAdminCount();
  }

  function _validateTreasuryAddress() internal logFn("_validateTreasuryAddress") {
    assertEq(_auction.getTreasury(), address(_commission));
    assertEq(_controller.getTreasury(), address(_commission));
  }

  function _validateNewAdmin() internal logFn("_validateNewAdmin") {
    address newAdmin = _nextAdmin;
    require(_auction.hasRole(DEFAULT_ADMIN_ROLE, newAdmin));
    require(_controller.hasRole(DEFAULT_ADMIN_ROLE, newAdmin));
  }

  function _validatePrevAdminIsRevoked() internal logFn("_validatePrevAdminIsRevoked") {
    address prevAdmin = _currentAdmin;
    require(!_auction.hasRole(DEFAULT_ADMIN_ROLE, prevAdmin));
    require(!_controller.hasRole(DEFAULT_ADMIN_ROLE, prevAdmin));
  }

  function _validateAdminCount() internal logFn("_validateAdminCount") {
    assertEq(_auction.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
    assertEq(_controller.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
  }
}
