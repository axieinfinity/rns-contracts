pragma solidity ^0.8.19;

import "./RNSCommission.t.sol";
import { console2, Test } from "forge-std/Test.sol";

contract RNSCommisson__allocateCommissionAndTransferToRecipient_Test is RNSCommissionTest {
  function test__allocateCommissionAndTransferToRecipient_SenderRole_MultiRecipient(uint256 amountRON) external {
    vm.assume(amountRON > 0);
    vm.assume(amountRON < 1e9 * 1e18);

    vm.deal(_senders[0], amountRON);
    bool sent;
    vm.prank(_senders[0]);
    (sent,) = address(_rnsCommission).call{ value: amountRON }(new bytes(0));

    uint256 maxPercentage = 100_00;
    uint256 skyMavisValue = (amountRON * _skyMavisRatio) / maxPercentage;
    assertEq(skyMavisValue, _skyMavisTreasuryAddr.balance);

    uint256 roninValue = amountRON - skyMavisValue;
    assertEq(roninValue, _roninNetworkTreasuryAddr.balance);
    assertEq(_senders[0].balance, 0);
  }

  function test__allocateCommissionAndTransferToRecipient_SenderRole_OnlyOneRecipient(uint256 amountRON) external {
    vm.assume(amountRON > 0);
    vm.assume(amountRON < 1e9 * 1e18);

    INSCommission.Commission[] memory treasuryCommission = new INSCommission.Commission[](1);
    address payable recipient = payable(makeAddr("recipient"));
    treasuryCommission[0].recipient = recipient;
    treasuryCommission[0].ratio = 100_00;
    treasuryCommission[0].name = "recipient";

    vm.prank(_admin);
    _setCommissions(treasuryCommission);

    vm.deal(_senders[0], amountRON);
    bool sent;
    vm.prank(_senders[0]);
    (sent,) = address(_rnsCommission).call{ value: amountRON }(new bytes(0));

    assertEq(recipient.balance, amountRON);
    assertEq(address(_rnsCommission).balance, 0);
    assertEq(_senders[0].balance, 0);
  }

  function test__allocateCommissionAndTransferToRecipient_InvalidSender(uint256 amountRON) external {
    vm.assume(amountRON > 0);
    vm.assume(amountRON < 1e9 * 1e18);

    address random = makeAddr("random");
    vm.deal(random, amountRON);
    bool sent;
    vm.prank(random);
    (sent,) = address(_rnsCommission).call{ value: amountRON }(new bytes(0));

    assertEq(_skyMavisTreasuryAddr.balance, 0);
    assertEq(_roninNetworkTreasuryAddr.balance, 0);
    assertEq(address(_rnsCommission).balance, amountRON);
    assertEq(random.balance, 0);
  }

  function test_RevertWhen_RonAmount_is_zero() external {
    vm.deal(_senders[0], 1e18);

    bool sent;
    vm.expectRevert(INSCommission.InvalidAmountOfRON.selector);
    vm.prank(_senders[0]);
    (sent,) = address(_rnsCommission).call{ value: 0 }(new bytes(0));
  }
}
