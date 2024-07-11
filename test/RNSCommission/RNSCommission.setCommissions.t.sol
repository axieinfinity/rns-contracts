// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSCommission.t.sol";
import { console2, Test } from "forge-std/Test.sol";

contract RNSCommisson_SetTreasuries_Test is RNSCommissionTest {
  function test_SetCommissions_As_Admin() external {
    address payable[] memory treasuriesAddress = new address payable[](2);
    uint256[] memory ratio = new uint256[](2);
    ratio[0] = _skyMavisRatio;
    ratio[1] = _roninRatio;

    treasuriesAddress[0] = payable(makeAddr("random0"));
    treasuriesAddress[1] = payable(makeAddr("random1"));

    INSCommission.Commission[] memory commissionInfo = _createCommissionInfo(treasuriesAddress, ratio, _names);

    vm.expectEmit(true, false, false, true);
    emit CommissionsUpdated(_admin, commissionInfo);

    vm.prank(_admin);
    _setCommissions(commissionInfo);

    INSCommission.Commission[] memory commissionInfoAfterSet = _rnsCommission.getCommissions();

    assertEq(commissionInfo[0].recipient, commissionInfoAfterSet[0].recipient);
    assertEq(commissionInfo[1].recipient, commissionInfoAfterSet[1].recipient);
  }

  function test_Revert_When_Invalid_Length(INSCommission.Commission[] memory treasuriesInfo) external {
    treasuriesInfo = new INSCommission.Commission[](0);
    vm.expectRevert(INSCommission.InvalidArrayLength.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissions(treasuriesInfo);
  }

  function test_Revert_When_Ratio_GreaterThan_100_MultiCommission() external {
    address payable[] memory treasuriesAddress = new address payable[](2);
    uint256[] memory ratio = new uint256[](2);
    ratio[0] = 100_00;
    ratio[1] = 1_00;

    treasuriesAddress[0] = payable(makeAddr("random0"));
    treasuriesAddress[1] = payable(makeAddr("random1"));

    INSCommission.Commission[] memory commissionInfo = _createCommissionInfo(treasuriesAddress, ratio, _names);

    vm.expectRevert(INSCommission.InvalidRatio.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissions(commissionInfo);
  }

  function test_Revert_When_Ratio_LessThan_100_MultiCommission() external {
    address payable[] memory treasuriesAddress = new address payable[](2);
    uint256[] memory ratio = new uint256[](2);
    ratio[0] = 90_00;
    ratio[1] = 1_00;

    treasuriesAddress[0] = payable(makeAddr("random0"));
    treasuriesAddress[1] = payable(makeAddr("random1"));

    INSCommission.Commission[] memory commissionInfo = _createCommissionInfo(treasuriesAddress, ratio, _names);

    vm.expectRevert(INSCommission.InvalidRatio.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissions(commissionInfo);
  }

  function test_Revert_When_Ratio_GreaterThan_100_OnlyOne_Commission() external {
    address payable[] memory treasuriesAddress = new address payable[](1);
    uint256[] memory ratio = new uint256[](1);
    ratio[0] = 101_00;

    treasuriesAddress[0] = payable(makeAddr("random0"));

    INSCommission.Commission[] memory commissionInfo = _createCommissionInfo(treasuriesAddress, ratio, _names);

    vm.expectRevert(INSCommission.InvalidRatio.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissions(commissionInfo);
  }

  function test_Revert_When_Ratio_LessThan_100_OnlyOne_Commission() external {
    address payable[] memory treasuriesAddress = new address payable[](1);
    uint256[] memory ratio = new uint256[](1);
    ratio[0] = 90_00;

    treasuriesAddress[0] = payable(makeAddr("random0"));

    INSCommission.Commission[] memory commissionInfo = _createCommissionInfo(treasuriesAddress, ratio, _names);

    vm.expectRevert(INSCommission.InvalidRatio.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissions(commissionInfo);
  }
}
