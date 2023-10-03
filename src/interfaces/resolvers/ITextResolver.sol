// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITextResolver {
  /// @dev Emitted when a node text is changed.
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key, string value);

  /**
   * @dev Sets the text data associated with an INS node and key.
   *
   * Requirements:
   * - The method caller must be authorized to change user fields of RNS Token `node`. See indicator
   * {ModifyingIndicator.USER_FIELDS_INDICATOR}.
   *
   * Emits an event {TextChanged}.
   *
   * @param node The node to update.
   * @param key The key to set.
   * @param value The text data value to set.
   */
  function setText(bytes32 node, string calldata key, string calldata value) external;

  /**
   * Returns the text data associated with an INS node and key.
   * @param node The INS node to query.
   * @param key The text data key to query.
   * @return The associated text data.
   */
  function text(bytes32 node, string calldata key) external view returns (string memory);
}
