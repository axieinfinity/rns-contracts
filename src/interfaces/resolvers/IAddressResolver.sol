// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAddressResolver {
  /// @dev Emitted when an address of a node is changed.
  event AddrChanged(bytes32 indexed node, address addr);

  /**
   * @dev Sets the address associated with an ENS node.
   *
   * Requirement:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {AddrChanged}.
   *
   * @param node The node to update.
   * @param addr The address to set.
   */
  function setAddr(bytes32 node, address addr) external;

  /**
   * @dev Returns the address associated with an ENS node.
   * @param node The ENS node to query.
   * @return The associated address.
   */
  function addr(bytes32 node) external view returns (address payable);
}
