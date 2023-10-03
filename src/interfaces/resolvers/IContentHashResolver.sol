// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContentHashResolver {
  /// @dev Emitted when the content hash of a node is changed.
  event ContentHashChanged(bytes32 indexed node, bytes hash);

  /**
   * @dev Sets the content hash associated with an ENS node.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {ContentHashChanged}.
   *
   * @param node The node to update.
   * @param hash The content hash to set
   */
  function setContentHash(bytes32 node, bytes calldata hash) external;

  /**
   * @dev Returns the content hash associated with an ENS node.
   * @param node The ENS node to query.
   * @return The associated content hash.
   */
  function contentHash(bytes32 node) external view returns (bytes memory);
}
