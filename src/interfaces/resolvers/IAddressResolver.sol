// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAddressResolver {
  /// @dev Emitted when an address of a node is changed.
  event AddrChanged(bytes32 indexed node, address addr);

  /**
   * @dev Sets the address associated with an INS node.
   *
   * Requirement:
   * - The method caller must be authorized to change user fields of RNS Token `node`. See indicator
   * {ModifyingIndicator.USER_FIELDS_INDICATOR}.
   *
   * Emits an event {AddrChanged}.
   *
   * @param node The node to update.
   * @param addr The address to set.
   */
  function setAddr(bytes32 node, address addr) external;

  /**
   * @dev Returns the address associated with an INS node.
   * @param node The INS node to query.
   * @return The associated address.
   */
  function addr(bytes32 node) external view returns (address payable);
}
