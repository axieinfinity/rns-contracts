// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { INameResolver } from "./resolvers/INameResolver.sol";
import { INSUnified } from "./INSUnified.sol";

/// @dev See https://eips.ethereum.org/EIPS/eip-181#registrar
interface IERC181 {
  /**
   * @dev Claims the name hex(addr) + '.addr.reverse' for addr.
   *
   * @param addr The address to set as the addr of the reverse record in INS.
   * @return id The INS node hash of the reverse record.
   */
  function claim(address addr) external returns (uint256 id);

  /**
   * @dev Claims the name hex(owner) + '.addr.reverse' for owner and sets resolver.
   *
   * @param addr The address to set as the owner of the reverse record in INS.
   * @param resolver The address of the resolver to set; 0 to leave unchanged.
   * @return id The INS node hash of the reverse record.
   */
  function claimWithResolver(address addr, address resolver) external returns (uint256 id);

  /**
   * @dev Sets the name record for the reverse INS record associated with the calling account. First updates the
   * resolver to the default reverse resolver if necessary.
   *
   * @param name The name to set for this address.
   * @return The INS node hash of the reverse record.
   */
  function setName(string memory name) external returns (uint256);
}

interface INSReverseRegistrar is IERC181, IERC165 {
  /// @dev Error: The provided id is not child node of `ADDR_REVERSE_ID`
  error InvalidId();
  /// @dev Error: The contract is not authorized for minting or modifying domain hex(addr) + '.addr.reverse'.
  error InvalidConfig();
  /// @dev Error: The sender lacks the necessary permissions.
  error Unauthorized();
  /// @dev Error: The provided resolver address is null.
  error NullAssignment();

  /// @dev Emitted when reverse node is claimed.
  event ReverseClaimed(address indexed addr, uint256 indexed id);
  /// @dev Emitted when the default resolver is changed.
  event DefaultResolverChanged(INameResolver indexed resolver);

  /**
   * @dev Returns the controller role.
   */
  function CONTROLLER_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns default resolver.
   */
  function getDefaultResolver() external view returns (INameResolver);

  /**
   * @dev Returns RNSUnified contract.
   */
  function getRNSUnified() external view returns (INSUnified);

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
  function setNameForAddr(address addr, string memory name) external returns (uint256 id);

  /**
   * @dev Returns address that the reverse node resolves for.
   * Eg. node namehash('{addr}.addr.reverse') will always resolve for `addr`.
   */
  function getAddress(uint256 id) external view returns (address);

  /**
   * @dev Returns the id hash for a given account's reverse records.
   * @param addr The address to hash
   * @return The INS node hash.
   */
  function computeId(address addr) external pure returns (uint256);
}
