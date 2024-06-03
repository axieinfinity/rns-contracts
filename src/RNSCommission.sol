// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { INSCommission } from "./interfaces/INSCommission.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { RONTransferHelper } from "./libraries/transfers/RONTransferHelper.sol";

contract RNSCommission is Initializable, AccessControlEnumerable, INSCommission {
  uint256 public constant MAX_PERCENTAGE = 100_00;
  bytes32 public constant COMMISSION_SETTER_ROLE = keccak256("COMMISSION_SETTER_ROLE");

  /// @dev Gap for upgradability.
  uint256[50] private ____gap;

  Commission[] internal _commissionInfo;
  mapping(address => bool) public _allowedSenders;

  constructor() {
    _disableInitializers();
  }

  receive() external payable {
    if (_isAllowedSender(msg.sender)) {
      _allocateCommissionAndTransferToTreasury(msg.value);
    }
  }

  fallback() external payable {
    if (_isAllowedSender(msg.sender)) {
      _allocateCommissionAndTransferToTreasury(msg.value);
    }
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
      _allowedSenders[allowedSenders[i]] = true;
    }

    _setTreasuries(treasuryCommission);
  }

  /// @inheritdoc INSCommission
  function getTreasuries() external view returns (Commission[] memory treasuriesInfo) {
    return _commissionInfo;
  }

  /// @inheritdoc INSCommission
  function setTreasuries(Commission[] calldata treasuriesInfo) external onlyRole(COMMISSION_SETTER_ROLE) {
    _setTreasuries(treasuriesInfo);
  }

  /// @inheritdoc INSCommission
  function changeTreasuryInfo(address payable newAddr, bytes calldata name, uint256 treasuryId)
    external
    onlyRole(COMMISSION_SETTER_ROLE)
  {
    if (treasuryId < 0 || treasuryId > _commissionInfo.length - 1) {
      revert InvalidArrayLength();
    }

    _commissionInfo[treasuryId].recipient = newAddr;
    _commissionInfo[treasuryId].name = name;
    emit TreasuryInfoUpdated(newAddr, name, treasuryId);
  }

  /// @inheritdoc INSCommission
  function allowSender(address sender) external onlyRole(COMMISSION_SETTER_ROLE) {
    _allowedSenders[sender] = true;
  }

  /**
   * @dev Helper method to calculate allocations.
   */
  function _calcAllocations(uint256 totalAmount) internal view returns (Allocation[] memory allocs) {
    if (totalAmount == 0) {
      revert InvalidAmountOfRON();
    }
    uint256 length = _commissionInfo.length;

    allocs = new Allocation[](length);

    uint256 lastIdx = length - 1;
    uint256 sumValue;

    for (uint256 i; i < lastIdx; ++i) {
      allocs[i] = Allocation({
        recipient: _commissionInfo[i].recipient,
        value: _computePercentage(totalAmount, _commissionInfo[i].ratio)
      });
      sumValue += allocs[i].value;
    }

    // Refund the remaining RON to the last treasury
    if (sumValue < totalAmount) {
      allocs[lastIdx] = Allocation({ recipient: _commissionInfo[lastIdx].recipient, value: totalAmount - sumValue });
    }
  }

  /**
   * @dev Helper method to allocate commission and take fee into treasuries address.
   */
  function _allocateCommissionAndTransferToTreasury(uint256 ronAmount) internal {
    INSCommission.Allocation[] memory allocs = _calcAllocations(ronAmount);
    uint256 length = allocs.length;

    for (uint256 i = 0; i < length; ++i) {
      uint256 value = allocs[i].value;
      address payable recipient = allocs[i].recipient;

      RONTransferHelper.safeTransfer(recipient, value);
    }
  }

  function _setTreasuries(Commission[] calldata treasuriesInfo) internal {
    uint256 length = treasuriesInfo.length;
    // treasuriesInfo[] can not be empty
    if (length < 1) revert InvalidArrayLength();

    delete _commissionInfo;

    uint256 sum = 0;

    for (uint256 i = 0; i < length; ++i) {
      sum += treasuriesInfo[i].ratio;
      _commissionInfo.push(treasuriesInfo[i]);
    }

    if (sum != MAX_PERCENTAGE) revert InvalidRatio();

    emit TreasuriesUpdated(treasuriesInfo);
  }

  /// Check if `sender` is allowed to send money
  function _isAllowedSender(address sender) internal view returns (bool) {
    return _allowedSenders[sender];
  }

  // Calculate amount of money based on treasury's ratio
  function _computePercentage(uint256 value, uint256 percentage) internal pure virtual returns (uint256) {
    return Math.mulDiv(value, percentage, MAX_PERCENTAGE);
  }
}
