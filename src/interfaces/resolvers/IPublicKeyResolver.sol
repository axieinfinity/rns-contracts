// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPublicKeyResolver {
  struct PublicKey {
    bytes32 x;
    bytes32 y;
  }

  /// @dev Emitted when a node public key is changed.
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

  /**
   * @dev Sets the SECP256k1 public key associated with an INS node.
   *
   * Requirements:
   * - The method caller must be authorized to change user fields of RNS Token `node`. See indicator
   * {ModifyingIndicator.USER_FIELDS_INDICATOR}.
   *
   * Emits an event {PubkeyChanged}.
   *
   * @param node The INS node to query
   * @param x the X coordinate of the curve point for the public key.
   * @param y the Y coordinate of the curve point for the public key.
   */
  function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;

  /**
   * @dev Returns the SECP256k1 public key associated with an INS node.
   * Defined in EIP 619.
   *
   * @param node The INS node to query
   * @return x The X coordinate of the curve point for the public key.
   * @return y The Y coordinate of the curve point for the public key.
   */
  function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}
