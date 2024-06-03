// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRNSCommission {
  struct Commission {
    address payable recipient;
    uint256 ratio; // Values [0; 100_00] reflexes [0; 100%]
    bytes name; // Treasury's name
  }

  struct Allocation {
    address payable recipient;
    uint256 value;
  }

  /// @dev Emitted when all the treasury info info are replaced.
  event TreasuriesReplaced(Commission[] treasuriesInfo);
  /// @dev Emitted when specific treasury info are updated.
  event TreasuryInfoUpdated(address payable treasuryAddr, bytes name, uint256 treasuryId);

  /// @dev Revert when index is out of range
  error InvalidArrayLength();
  /// @dev Revert when ratio is invalid
  error InvalidRatio();
  /// @dev Revert when amount of RON is invalid
  error InvalidAmountOfRON();

  /**
   * @dev Returns all treasury.
   */
  function getTreasuries() external view returns (Commission[] memory treasuriesInfo);

  /**
   * @dev Replaces all treasuries information
   *
   * Requirements:
   * - The method caller is setter role.
   * - The total ratio must be equal to 100%.
   * Emits the event `TreasuriesPreplaced`.
   */
  function replaceTreasuries(Commission[] calldata treasuriesInfo) external;

  /**
   * @dev Sets for specific treasury information based on the treasury `id`.
   *
   * Requirements:
   * - The method caller is setter role.
   * Emits the event `TreasuryInfoUpdated`.
   */
  function changeTreasuryInfo(address payable newAddr, bytes calldata name, uint256 treasuryId) external;
}
