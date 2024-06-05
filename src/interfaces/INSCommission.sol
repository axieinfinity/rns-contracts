// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INSCommission {
  struct Commission {
    address payable recipient;
    uint256 ratio; // Values [0; 100_00] reflexes [0; 100%]
    string name; // Commission's name
  }

  struct Allocation {
    address payable recipient;
    uint256 value;
  }

  /// @dev Emitted when all the commission info is updated.
  event CommissionsUpdated(address indexed updatedBy, Commission[] commissionInfos);
  /// @dev Emitted when specific commission info is updated.
  event CommissionInfoUpdated(
    address indexed updatedBy, address payable newRecipient, string name, uint256 indexed commissionIdx
  );

  /// @dev Revert when index is out of range
  error InvalidArrayLength();
  /// @dev Revert when ratio is invalid
  error InvalidRatio();
  /// @dev Revert when amount of RON is invalid
  error InvalidAmountOfRON();

  /**
   * @dev Returns comissions information.
   */
  function getCommissions() external view returns (Commission[] memory commissionInfos);

  /**
   * @dev Sets all commission information
   *
   * Requirements:
   * - The method caller is setter role.
   * - The total ratio must be equal to 100%.
   * Emits the event `CommissionsUpdated`.
   */
  function setCommissions(Commission[] calldata commissionInfos) external;

  /**
   * @dev Sets for specific commission information based on the `commissionIdx`.
   *
   * Requirements:
   * - The method caller is setter role.
   * Emits the event `CommissionInfoUpdated`.
   */
  function setCommissionInfo(uint256 commissionIdx, address payable newAddr, string calldata name) external;
}
