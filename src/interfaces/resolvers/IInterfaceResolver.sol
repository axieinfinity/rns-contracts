// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInterfaceResolver {
  /// @dev Emitted when the interface of node is changed.
  event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

  /**
   * @dev Sets an interface associated with a name.
   * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
   *
   * Requirements:
   * - The method caller must be authorized to change user fields of RNS Token `node`. See indicator
   * {ModifyingIndicator.USER_FIELDS_INDICATOR}.
   *
   * @param node The node to update.
   * @param interfaceID The EIP 165 interface ID.
   * @param implementer The address of a contract that implements this interface for this node.
   */
  function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;

  /**
   * @dev Returns the address of a contract that implements the specified interface for this name.
   *
   * If an implementer has not been set for this interfaceID and name, the resolver will query the contract at `addr()`.
   * If `addr()` is set, a contract exists at that address, and that contract implements EIP165 and returns `true` for
   * the specified interfaceID, its address will be returned.
   *
   * @param node The INS node to query.
   * @param interfaceID The EIP 165 interface ID to check for.
   * @return The address that implements this interface, or 0 if the interface is unsupported.
   */
  function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}
