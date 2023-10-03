// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INameResolver {
  /// @dev Emitted when a node name is changed.
  event NameChanged(bytes32 indexed node, string name);

  /**
   * @dev Sets the name associated with an ENS node, for reverse records.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {NameChanged}.
   *
   * @param node The node to update.
   */
  function setName(bytes32 node, string calldata newName) external;

  /**
   * @dev Returns the name associated with an ENS node, for reverse records. Defined in EIP181.
   * @param node The ENS node to query.
   * @return The associated name.
   */
  function name(bytes32 node) external view returns (string memory);
}
