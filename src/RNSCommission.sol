// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { INSCommission } from "./interfaces/INSCommission.sol";
import { RONTransferHelper } from "./libraries/transfers/RONTransferHelper.sol";

contract RNSCommission is Initializable, AccessControlEnumerable, INSCommission {
  /// @dev Constant representing the maximum percentage value (100%).
  uint256 public constant MAX_PERCENTAGE = 100_00;
  /// @dev Role for accounts that can send RON for this contract.
  bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;
  /// @dev Array of `Commission` structs that store commissions information.
  Commission[] internal _commissionInfos;

  constructor() {
    _disableInitializers();
  }

  receive() external payable {
    _fallback();
  }

  function initialize(address admin, Commission[] calldata commissionInfos, address[] calldata allowedSenders)
    external
    initializer
  {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    uint256 length = allowedSenders.length;
    for (uint256 i; i < length; ++i) {
      _setupRole(SENDER_ROLE, allowedSenders[i]);
    }

    _setCommissions(commissionInfos);
  }

  /// @inheritdoc INSCommission
  function getCommissions() external view returns (Commission[] memory commissionInfos) {
    return _commissionInfos;
  }

  /// @inheritdoc INSCommission
  function setCommissions(Commission[] calldata commissionInfos) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setCommissions(commissionInfos);
  }

  /// @inheritdoc INSCommission
  function setCommissionInfo(uint256 commissionIdx, address payable newRecipient, string calldata newName)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (commissionIdx >= _commissionInfos.length) revert InvalidArrayLength();
    // TODO: should fix to not duplicate logic in set commision info
    if (newRecipient == address(0)) revert NullAddress();

    _commissionInfos[commissionIdx].recipient = newRecipient;
    _commissionInfos[commissionIdx].name = newName;
    emit CommissionInfoUpdated(msg.sender, commissionIdx, newRecipient, newName);
  }

  /**
   * @dev Helper method to allocate commission and take fee into recipient address.
   */
  function _allocateCommissionAndTransferToRecipient(uint256 ronAmount) internal {
    if (ronAmount == 0) revert InvalidAmountOfRON();

    uint256 length = _commissionInfos.length;
    if (length == 0) revert InvalidArrayLength();

    uint256 lastIdx = length - 1;
    uint256 sumValue;

    for (uint256 i; i < lastIdx; ++i) {
      uint256 commissionAmount = _computePercentage(ronAmount, _commissionInfos[i].ratio);
      sumValue += commissionAmount;

      RONTransferHelper.safeTransfer(_commissionInfos[i].recipient, commissionAmount);
      emit Distributed(_commissionInfos[i].recipient, commissionAmount);
    }

    // This code send the remaining RON to the last recipient.
    if (sumValue < ronAmount) {
      RONTransferHelper.safeTransfer(_commissionInfos[lastIdx].recipient, ronAmount - sumValue);
      emit Distributed(_commissionInfos[lastIdx].recipient, ronAmount - sumValue);
    }
  }

  function _setCommissions(Commission[] calldata commissionInfos) internal {
    uint256 length = commissionInfos.length;
    // commissionInfos[] can not be empty
    if (length == 0) revert InvalidArrayLength();

    delete _commissionInfos;

    uint256 sum;

    for (uint256 i; i < length; ++i) {
      if (commissionInfos[i].recipient == address(0)) revert NullAddress();

      sum += commissionInfos[i].ratio;
      _commissionInfos.push(commissionInfos[i]);
    }

    if (sum != MAX_PERCENTAGE) revert InvalidRatio();

    emit CommissionsUpdated(msg.sender, commissionInfos);
  }

  // Calculate amount of money based on commission's ratio
  function _computePercentage(uint256 value, uint256 percentage) internal pure virtual returns (uint256) {
    return (value * percentage) / MAX_PERCENTAGE;
  }

  function _fallback() internal {
    if (hasRole(SENDER_ROLE, msg.sender)) {
      _allocateCommissionAndTransferToRecipient(msg.value);
    }
  }
}
