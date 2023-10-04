// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { ModifyingIndicator } from "../types/ModifyingIndicator.sol";

interface INSUnified is IERC721Metadata {
  /// @dev Error: The provided token id is expired.
  error Expired();
  /// @dev Error: The provided id expiry is greater than parent id expiry.
  error ExceedParentExpiry();
  /// @dev Error: The provided name is unavailable for registration.
  error Unavailable();
  /// @dev Error: The sender lacks the necessary permissions.
  error Unauthorized();
  /// @dev Error: Missing controller role required for modification.
  error MissingControllerRole();
  /// @dev Error: Attempting to set an immutable field, which cannot be modified.
  error CannotSetImmutableField();
  /// @dev Error: Missing protected settler role required for modification.
  error MissingProtectedSettlerRole();
  /// @dev Error: Attempting to set an expiry time that is not larger than the previous one.
  error ExpiryTimeMustBeLargerThanTheOldOne();
  /// @dev Error: The provided name must be registered or is in a grace period.
  error NameMustBeRegisteredOrInGracePeriod();

  /**
   * | Fields\Idc | Modifying Indicator |
   * | ---------- | ------------------- |
   * | depth      | 0b00000001          |
   * | parentId   | 0b00000010          |
   * | label      | 0b00000100          |
   */
  struct ImmutableRecord {
    // The level-th of a domain.
    uint8 depth;
    // The node of parent token. Eg, parent node of vip.dukethor.ron equals to namehash('dukethor.ron')
    uint256 parentId;
    // The label of a domain. Eg, label is vip for domain vip.dukethor.ron
    string label;
  }

  /**
   * | Fields\Idc,Roles | Modifying Indicator | Controller | Protected setter | (Parent) Owner/Spender |
   * | ---------------- | ------------------- | ---------- | ---------------- | ---------------------- |
   * | resolver         | 0b00001000          | x          |                  | x                      |
   * | ttl              | 0b00010000          | x          |                  | x                      |
   * | owner            | 0b00100000          | x          |                  | x                      |
   * | expiry           | 0b01000000          | x          |                  |                        |
   * | protected        | 0b10000000          |            | x                |                        |
   * Note: (Parent) Owner/Spender means parent owner or current owner or current token spender.
   */
  struct MutableRecord {
    // The resolver address.
    address resolver;
    // Duration in second(s) to live.
    uint64 ttl;
    // The record owner.
    address owner;
    // Expiry timestamp.
    uint64 expiry;
    // Flag indicating whether the token is protected or not.
    bool protected;
  }

  struct Record {
    ImmutableRecord immut;
    MutableRecord mut;
  }

  /// @dev Emitted when a base URI is updated.
  event BaseURIUpdated(address indexed operator, string newURI);
  event GracePeriodUpdated(address indexed operator, uint64 newGracePeriod);

  /**
   * @dev Emitted when records of node are updated.
   * @param indicator The binary index of updated fields. Eg, 0b10101011 means fields at position 1, 2, 4, 6, 8 (right
   * to left) needs to be updated.
   * @param record The updated fields.
   */
  event RecordsUpdated(uint256 indexed node, ModifyingIndicator indicator, Record record);

  /**
   * @dev Returns the controller role.
   * @notice Can set all fields {Record.mut} in token record, excepting {Record.mut.protected}.
   */
  function CONTROLLER_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns the protected setter role.
   * @notice Can set field {Record.mut.protected} in token record by using method `bulkSetProtected`.
   */
  function PROTECTED_SETTLER_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns the reservation role.
   * @notice Never expire for token owner has this role.
   */
  function RESERVATION_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns true if the specified name is available for registration.
   * Note: Only available after passing the grace period.
   */
  function available(uint256 id) external view returns (bool);

  /**
   * @dev Returns the grace period in second(s).
   * Note: This period affects the availability of the domain.
   */
  function getGracePeriod() external view returns (uint64);

  /**
   * @dev Returns the total minted ids.
   * Note: Burning id will not affect `totalMinted`.
   */
  function totalMinted() external view returns (uint256);

  /**
   * @dev Sets the grace period in second(s).
   *
   * Requirements:
   * - The method caller must have controller role.
   *
   * Note: This period affects the availability of the domain.
   */
  function setGracePeriod(uint64) external;

  /**
   * @dev Sets the base uri.
   *
   * Requirements:
   * - The method caller must be contract owner.
   *
   */
  function setBaseURI(string calldata baseTokenURI) external;

  /**
   * @dev Mints token for subnode.
   *
   * Requirements:
   * - The token must be available.
   * - The method caller must be (parent) owner or approved spender. See struct {MutableRecord}.
   *
   * Emits an event {RecordsUpdated}.
   *
   * @param parentId The parent node to mint or create subnode.
   * @param label The domain label. Eg, label is dukethor for domain dukethor.ron.
   * @param resolver The resolver address.
   * @param ttl Duration in second(s) to live.
   * @param owner The token owner.
   * @param duration Duration in second(s) to expire. Leave 0 to set as parent.
   */
  function mint(uint256 parentId, string calldata label, address resolver, uint64 ttl, address owner, uint64 duration)
    external
    returns (uint64 expiryTime, uint256 id);

  /**
   * @dev Returns all records of a domain.
   * Reverts if the token is non existent.
   */
  function getRecords(uint256 id) external view returns (Record memory records, string memory domain);

  /**
   * @dev Returns whether the requester is able to modify the records based on the updated index.
   * Note: This method strictly follows the permission of struct {MutableRecord}.
   */
  function canSetRecords(address requester, uint256 id, ModifyingIndicator indicator)
    external
    view
    returns (bool, bytes4 error);

  /**
   * @dev Sets records of existing token. Update operation for {Record.mut}.
   *
   * Requirements:
   * - The method caller must have role based on the corresponding `indicator`. See struct {MutableRecord}.
   *
   * Emits an event {RecordsUpdated}.
   */
  function setRecords(uint256 id, ModifyingIndicator indicator, MutableRecord calldata records) external;

  /**
   * @dev Reclaims ownership. Update operation for {Record.mut.owner}.
   *
   * Requirements:
   * - The method caller should have controller role.
   * - The method caller should be (parent) owner or approved spender. See struct {MutableRecord}.
   *
   * Emits an event {RecordsUpdated}.
   */
  function reclaim(uint256 id, address owner) external;

  /**
   * @dev Renews token. Update operation for {Record.mut.expiry}.
   *
   * Requirements:
   * - The method caller should have controller role.
   *
   * Emits an event {RecordsUpdated}.
   */
  function renew(uint256 id, uint64 duration) external;

  /**
   * @dev Sets expiry time for a token. Update operation for {Record.mut.expiry}.
   *
   * Requirements:
   * - The method caller must have controller role.
   *
   * Emits an event {RecordsUpdated}.
   */
  function setExpiry(uint256 id, uint64 expiry) external;

  /**
   * @dev Sets the protected status of a list of ids. Update operation for {Record.mut.protected}.
   *
   * Requirements:
   * - The method caller must have protected setter role.
   *
   * Emits events {RecordsUpdated}.
   */
  function bulkSetProtected(uint256[] calldata ids, bool protected) external;
}
