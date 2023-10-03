// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITextResolver {
  /// @dev Emitted when a node text is changed.
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key, string value);

  /**
   * @dev Sets the text data associated with an ENS node and key.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {TextChanged}.
   *
   * @param node The node to update.
   * @param key The key to set.
   * @param value The text data value to set.
   */
  function setText(bytes32 node, string calldata key, string calldata value) external;

  /**
   * Returns the text data associated with an ENS node and key.
   * @param node The ENS node to query.
   * @param key The text data key to query.
   * @return The associated text data.
   */
  function text(bytes32 node, string calldata key) external view returns (string memory);
}
