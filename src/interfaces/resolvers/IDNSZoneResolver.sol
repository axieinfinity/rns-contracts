// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
  /// @dev Emitted whenever a given node's zone hash is updated.
  event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

  /**
   * @dev Sets the hash for the zone.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * Emits an event {DNSZonehashChanged}.
   *
   * @param node The node to update.
   * @param hash The zonehash to set
   */
  function setZonehash(bytes32 node, bytes calldata hash) external;

  /**
   * @dev Obtains the hash for the zone.
   * @param node The ENS node to query.
   * @return The associated contenthash.
   */
  function zonehash(bytes32 node) external view returns (bytes memory);
}
