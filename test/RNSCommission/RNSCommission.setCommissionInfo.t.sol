pragma solidity ^0.8.19;

import "./RNSCommission.t.sol";
import { console2, Test } from "forge-std/Test.sol";

contract RNSCommisson_SetTreasuryInfo_Test is RNSCommissionTest {
  function test_setCommissionInfo_Success(address payable newAddr, uint256 id) external {
    uint256 treasuryCount = _rnsCommission.getCommissions().length;

    vm.assume(id < treasuryCount);

    vm.expectEmit(true, true, false, true);
    emit CommissionInfoUpdated(_admin, id, newAddr, "name");

    vm.prank(_admin);
    _rnsCommission.setCommissionInfo(id, newAddr, "name");

    INSCommission.Commission[] memory treasuriesInfoAfterChange = _rnsCommission.getCommissions();

    assertEq(treasuriesInfoAfterChange[id].recipient, newAddr);
    assertEq(treasuriesInfoAfterChange[id].name, "name");
  }

  function test_Revert_When_Invalid_Id(address payable newAddr, uint256 id) external {
    uint256 treasuryCount = _rnsCommission.getCommissions().length;

    vm.assume(id >= treasuryCount);

    vm.expectRevert(INSCommission.InvalidArrayLength.selector);
    vm.prank(_admin);
    _rnsCommission.setCommissionInfo(id, newAddr, "name");
  }
}
