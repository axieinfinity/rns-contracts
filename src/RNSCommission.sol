// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { INSCommission } from "./interfaces/INSCommission.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { RONTransferHelper } from "./libraries/transfers/RONTransferHelper.sol";

contract RNSCommission is Initializable, AccessControlEnumerable, INSCommission {
  /// @dev Constant representing the maximum percentage value (100%).
  uint256 public constant MAX_PERCENTAGE = 100_00;
  /// @dev Role for accounts that can set commissions infomation and grant or revoke `SENDER_ROLE`.
  bytes32 public constant COMMISSION_SETTER_ROLE = keccak256("COMMISSION_SETTER_ROLE");
  /// @dev Role for accounts that can send RON for this contract.
  bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");

  /// @dev Gap for upgradability.
  uint256[50] private ____gap;

  Commission[] internal _commissionInfos;

  constructor() {
    _disableInitializers();
  }

  receive() external payable {
    _fallback();
  }

  function initialize(
    address admin,
    address[] calldata commissionSetters,
    Commission[] calldata treasuryCommission,
    address[] calldata allowedSenders
  ) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    uint256 length = commissionSetters.length;
    for (uint256 i; i < length; ++i) {
      _setupRole(COMMISSION_SETTER_ROLE, commissionSetters[i]);
    }

    uint256 sendersLength = allowedSenders.length;
    for (uint256 i; i < sendersLength; ++i) {
      _setupRole(SENDER_ROLE, allowedSenders[i]);
    }

    _setRoleAdmin(SENDER_ROLE, COMMISSION_SETTER_ROLE);
    _setTreasuries(treasuryCommission);
  }

  /// @inheritdoc INSCommission
  function getCommissions() external view returns (Commission[] memory treasuriesInfo) {
    return _commissionInfos;
  }

  /// @inheritdoc INSCommission
  function setTreasuries(Commission[] calldata treasuriesInfo) external onlyRole(COMMISSION_SETTER_ROLE) {
    _setTreasuries(treasuriesInfo);
  }

  /// @inheritdoc INSCommission
  function setTreasuryInfo(uint256 treasuryId, address payable newAddr, string calldata name)
    external
    onlyRole(COMMISSION_SETTER_ROLE)
  {
    if (treasuryId > _commissionInfos.length - 1) {
      revert InvalidArrayLength();
    }

    _commissionInfos[treasuryId].recipient = newAddr;
    _commissionInfos[treasuryId].name = name;
    emit TreasuryInfoUpdated(msg.sender, newAddr, name, treasuryId);
  }

  /**
   * @dev Helper method to calculate allocations.
   */
  function _calcAllocations(uint256 totalAmount) internal view returns (Allocation[] memory allocs) {
    if (totalAmount == 0) {
      revert InvalidAmountOfRON();
    }
    uint256 length = _commissionInfos.length;

    allocs = new Allocation[](length);

    uint256 lastIdx = length - 1;
    uint256 sumValue;

    for (uint256 i; i < lastIdx; ++i) {
      allocs[i] = Allocation({
        recipient: _commissionInfos[i].recipient,
        value: _computePercentage(totalAmount, _commissionInfos[i].ratio)
      });
      sumValue += allocs[i].value;
    }

    // This code replaces value of the last recipient.
    if (sumValue < totalAmount) {
      allocs[lastIdx] = Allocation({ recipient: _commissionInfos[lastIdx].recipient, value: totalAmount - sumValue });
    }
  }

  /**
   * @dev Helper method to allocate commission and take fee into treasuries address.
   */
  function _allocateCommissionAndTransferToTreasury(uint256 ronAmount) internal {
    INSCommission.Allocation[] memory allocs = _calcAllocations(ronAmount);
    uint256 length = allocs.length;

    for (uint256 i; i < length; ++i) {
      uint256 value = allocs[i].value;
      address payable recipient = allocs[i].recipient;

      RONTransferHelper.safeTransfer(recipient, value);
    }
  }

  function _setTreasuries(Commission[] calldata treasuriesInfo) internal {
    uint256 length = treasuriesInfo.length;
    // treasuriesInfo[] can not be empty
    if (length == 0) revert InvalidArrayLength();

    delete _commissionInfos;

    uint256 sum;

    for (uint256 i; i < length; ++i) {
      sum += treasuriesInfo[i].ratio;
      _commissionInfos.push(treasuriesInfo[i]);
    }

    if (sum != MAX_PERCENTAGE) revert InvalidRatio();

    emit TreasuriesUpdated(msg.sender, treasuriesInfo);
  }

  // Calculate amount of money based on treasury's ratio
  function _computePercentage(uint256 value, uint256 percentage) internal pure virtual returns (uint256) {
    return Math.mulDiv(value, percentage, MAX_PERCENTAGE);
  }

  function _fallback() internal {
    if (hasRole(SENDER_ROLE, msg.sender)) {
      _allocateCommissionAndTransferToTreasury(msg.value);
    }
  }
}
