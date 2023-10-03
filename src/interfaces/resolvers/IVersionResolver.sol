// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionResolver {
  /// @dev Emitted when the version of a node is changed.
  event VersionChanged(bytes32 indexed node, uint64 newVersion);

  /**
   * @dev Increments the record version associated with an ENS node.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {VersionChanged}.
   *
   * @param node The node to update.
   */
  function clearRecords(bytes32 node) external;

  /**
   * @dev Returns the latest version of a node.
   */
  function recordVersions(bytes32 node) external view returns (uint64);
}
