// SPDX-LicINSe-Identifier: UNLICINSED
pragma solidity ^0.8.0;

import { INameResolver } from "./resolvers/INameResolver.sol";

/// @dev See https://eips.ethereum.org/EIPS/eip-181#registrar
interface IERC181 {
  /**
   * @dev Claims the name hex(addr) + '.addr.reverse' for addr.
   *
   * @param addr The address to set as the addr of the reverse record in INS.
   * @return node The INS node hash of the reverse record.
   */
  function claim(address addr) external returns (bytes32 node);

  /**
   * @dev Claims the name hex(owner) + '.addr.reverse' for owner and sets resolver.
   *
   * @param addr The address to set as the owner of the reverse record in INS.
   * @param resolver The address of the resolver to set; 0 to leave unchanged.
   * @return node The INS node hash of the reverse record.
   */
  function claimWithResolver(address addr, address resolver) external returns (bytes32 node);

  /**
   * @dev Sets the name record for the reverse INS record associated with the calling account. First updates the
   * resolver to the default reverse resolver if necessary.
   *
   * @param name The name to set for this address.
   * @return The INS node hash of the reverse record.
   */
  function setName(string memory name) external returns (bytes32);
}

interface IReverseRegistrar is IERC181 {
  /// @dev Emitted when reverse node is claimed.
  event ReverseClaimed(address indexed addr, bytes32 indexed node);
  /// @dev Emitted when the default resolver is changed.
  event DefaultResolverChanged(INameResolver indexed resolver);

  /**
   * @dev Returns default resolver.
   */
  function defaultResolver() external view returns (INameResolver);

  /**
   * @dev Sets default resolver.
   *
   * Requirement:
   *
   * - The method caller must be admin.
   *
   * Emitted an event {DefaultResolverChanged}.
   *
   */
  function setDefaultResolver(INameResolver resolver) external;

  /**
   * @dev Same as {IERC181-setName}.
   */
  function setNameForAddr(address addr, string memory name) external returns (bytes32 node);

  /**
   * @dev Returns address that the reverse node resolves for.
   * Eg. node namehash('{addr}.addr.reverse') will always resolve for `addr`.
   */
  function getAddress(bytes32 node) external view returns (address);

  /**
   * @dev Returns the node hash for a given account's reverse records.
   * @param addr The address to hash
   * @return The INS node hash.
   */
  function computeNode(address addr) external pure returns (bytes32);
}
