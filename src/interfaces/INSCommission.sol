// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INSCommission {
  struct Commission {
    address payable recipient;
    uint256 ratio; // Values [0; 100_00] reflexes [0; 100%]
    string name; // Treasury's name
  }

  struct Allocation {
    address payable recipient;
    uint256 value;
  }

  /// @dev Emitted when all the treasury info info are updated.
  event TreasuriesUpdated(address indexed updatedBy, Commission[] treasuriesInfo);
  /// @dev Emitted when specific treasury info are updated.
  event TreasuryInfoUpdated(
    address indexed updatedBy, address payable treasuryAddr, string name, uint256 indexed treasuryId
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
  function getCommissions() external view returns (Commission[] memory treasuriesInfo);

  /**
   * @dev Sets all treasuries information
   *
   * Requirements:
   * - The method caller is setter role.
   * - The total ratio must be equal to 100%.
   * Emits the event `TreasuriesUpdated`.
   */
  function setTreasuries(Commission[] calldata treasuriesInfo) external;

  /**
   * @dev Sets for specific treasury information based on the treasury `id`.
   *
   * Requirements:
   * - The method caller is setter role.
   * Emits the event `TreasuryInfoUpdated`.
   */
  function setTreasuryInfo(uint256 treasuryId, address payable newAddr, string calldata name) external;
}
