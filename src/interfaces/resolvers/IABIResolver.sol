// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IABIResolver {
  /// Thrown when the input content type is invalid.
  error InvalidContentType();

  /// @dev Emitted when the ABI is changed.
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

  /**
   * @dev Sets the ABI associated with an ENS node. Nodes may have one ABI of each content type. To remove an ABI, set it
   * to the empty string.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   * - The content type must be powers of 2.
   *
   * Emitted an event {ABIChanged}.
   *
   * @param node The node to update.
   * @param contentType The content type of the ABI
   * @param data The ABI data.
   */
  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;

  /**
   * @dev Returns the ABI associated with an ENS node.
   * Defined in EIP-205, see more at https://eips.ethereum.org/EIPS/eip-205
   *
   * @param node The ENS node to query
   * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
   * @return contentType The content type of the return value
   * @return data The ABI data
   */
  function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256 contentType, bytes memory data);
}
