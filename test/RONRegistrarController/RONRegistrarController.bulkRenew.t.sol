// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console2, Test } from "forge-std/Test.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import {
  RONRegistrarController,
  IRONRegistrarController,
  INSUnified,
  INameChecker,
  INSDomainPrice,
  INSReverseRegistrar
} from "@rns-contracts/RONRegistrarController.sol";
import { RONTransferHelper } from "@rns-contracts/libraries/transfers/RONTransferHelper.sol";
import { LibString } from "@rns-contracts/libraries/LibString.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { RONRegistrarControllerTest } from "./RONRegistrarController.t.sol";

contract RONRegistrarControllerBulkRenewTest is RONRegistrarControllerTest {
  event NameRenewed(string name, uint256 indexed id, uint256 cost, uint64 expires);

  function testConcreate_Renew_2names_Check_CorrectFeeCharged() external {
    string[] memory names = new string[](2);
    names[0] = "tori.ron";
    names[1] = "test.ron";

    (uint256[] memory ids, string[] memory sortedNames) = _sortNames(names);
    uint64[] memory expires = new uint64[](ids.length);
    uint64 duration = 30 days;
    for (uint256 i; i < ids.length; ++i) {
      console2.log("id", ids[i]);
      console2.log("name", sortedNames[i]);
      expires[i] = _rnsUnified.getRecord(ids[i]).mut.expiry + duration;
    }

    uint256[] memory fees = new uint256[](2);
    fees[0] = _calFee(names[0], duration);
    fees[1] = _calFee(names[1], duration);

    uint256 totalFee = fees[0] + fees[1];

    uint256 sendValue = 10 ether;
    uint256 balanceBefore = address(_caller).balance;

    uint64[] memory durations = new uint64[](2);
    durations[0] = duration;
    durations[1] = duration;
    _expectEmit(sortedNames, ids, fees, expires);
    vm.prank(_caller);
    _controller.bulkRenew{ value: sendValue }(sortedNames, durations);
    assertEq(address(_caller).balance, balanceBefore - totalFee);

    durations[0] = duration;
    durations[1] = duration;
    vm.prank(_caller);
    _controller.bulkRenew{ value: sendValue }(sortedNames, durations);
  }

  function testConcreate_bulkRenew_TheSameName_CorrectFeeCharged() external {
    string[] memory names = new string[](2);
    names[0] = "tori.vip.ron";
    names[1] = "tori.vip.ron";

    uint64 duration = 30 days;
    uint64[] memory durations = new uint64[](2);
    durations[0] = duration;
    durations[1] = duration;
    uint256 balanceBefore = address(_caller).balance;

    uint256 fee = _calFee(names[0], duration) * 2;

    vm.prank(_caller);
    _controller.bulkRenew{ value: 10 ether }(names, durations);

    assertEq(address(_caller).balance, balanceBefore - fee);
    assertEq(_treasury.balance, fee);
  }

  function testRevert_bulkRenew_InsufficientValue() external {
    string[] memory names = new string[](2);
    names[0] = "test.ron";
    names[1] = "tori.ron";

    uint64 duration = 30 days;
    uint64[] memory durations = new uint64[](2);
    durations[0] = duration;
    durations[1] = duration;

    uint256 name0Fee = _calFee(names[0], duration);
    uint256 name1Fee = _calFee(names[1], duration);

    vm.prank(_caller);
    vm.expectRevert(IRONRegistrarController.InsufficientValue.selector);
    _controller.bulkRenew{ value: name0Fee + name1Fee - 1 }(names, durations);

    // Call success
    _controller.bulkRenew{ value: name0Fee + name1Fee }(names, durations);
  }

  function testRevert_bulkRenew_ExpiryNotLargerThanOldOne() external {
    string[] memory names = new string[](1);
    names[0] = "test.ron";

    uint64[] memory durations = new uint64[](1);
    durations[0] = 0;

    vm.prank(_caller);
    vm.expectRevert(INSUnified.ExpiryTimeMustBeLargerThanTheOldOne.selector);
    _controller.bulkRenew{ value: 10 ether }(names, durations);
  }

  function testBenchMark_bulkRenew(uint8 times) external {
    vm.pauseGasMetering();
    vm.assume(times > 0);
    string[] memory names = new string[](times);
    uint64[] memory durations = new uint64[](times);
    uint256 totalFee;
    for (uint256 i; i < times; ++i) {
      names[i] = string.concat("test", vm.toString(i), ".ron");
      durations[i] = 30 days;
      totalFee += _calFee(names[i], durations[i]);
    }
    vm.deal(_caller, totalFee + 10 ether);
    (, string[] memory sortedNames) = _sortNames(names);
    vm.resumeGasMetering();
    vm.prank(_caller);
    _controller.bulkRenew{ value: totalFee + 10 ether }(sortedNames, durations);

    assertEq(address(_caller).balance, 10 ether);
    assertEq(_treasury.balance, totalFee);
  }

  function testRevert_bulkRenew_InvalidArrayLength() external {
    string[] memory names = new string[](2);
    names[0] = "test.ron";
    names[1] = "tori.ron";

    uint64[] memory durations = new uint64[](1);
    durations[0] = 30 days;

    vm.prank(_caller);
    vm.expectRevert(IRONRegistrarController.InvalidArrayLength.selector);
    _controller.bulkRenew{ value: 10 ether }(names, durations);

    names = new string[](0);
    durations = new uint64[](0);
    vm.expectRevert(IRONRegistrarController.InvalidArrayLength.selector);
    _controller.bulkRenew{ value: 10 ether }(names, durations);
  }

  function testConcreate_DuplicateNames_With_TheSameDuration() external {
    string[] memory names = new string[](2);
    names[0] = "test.ron";
    names[1] = "test.ron";

    uint64[] memory durations = new uint64[](2);
    durations[0] = 30 days;
    durations[1] = 30 days;

    vm.prank(_caller);
    // vm.expectRevert(IRONRegistrarController.InvalidArrayLength.selector);
    _controller.bulkRenew{ value: 10 ether }(names, durations);
  }

  function testConcreate_DuplicateNames_With_DifferentDuration() external {
    string[] memory names = new string[](2);
    names[0] = "test.ron";
    names[1] = "test.ron";

    uint64[] memory durations = new uint64[](2);
    durations[0] = 30 days;
    durations[1] = 10 days;

    vm.prank(_caller);
    // vm.expectRevert(IRONRegistrarController.InvalidArrayLength.selector);
    _controller.bulkRenew{ value: 10 ether }(names, durations);
  }

  function _calFee(string memory name, uint64 duration) internal returns (uint256) {
    (, uint256 ronPrice) = _controller.rentPrice(name, duration);
    return ronPrice;
  }

  function _sortNames(string[] memory names) internal returns (uint256[] memory, string[] memory) {
    uint256[] memory ids = new uint256[](names.length);
    for (uint256 i = 0; i < names.length; i++) {
      ids[i] = _controller.computeId(names[i]);
    }

    for (uint256 i = 0; i < names.length; i++) {
      for (uint256 j = i + 1; j < names.length; j++) {
        if (ids[i] > ids[j]) {
          uint256 tempId = ids[i];
          ids[i] = ids[j];
          ids[j] = tempId;

          string memory tempName = names[i];
          names[i] = names[j];
          names[j] = tempName;
        }
      }
    }
    return (ids, names);
  }

  function _expectEmit(string[] memory names, uint256[] memory ids, uint256[] memory fees, uint64[] memory expires)
    internal
  {
    for (uint256 i; i < names.length; ++i) {
      vm.expectEmit(false, true, false, true);
      emit NameRenewed(names[i], ids[i], fees[i], expires[i]);
    }
  }
}
