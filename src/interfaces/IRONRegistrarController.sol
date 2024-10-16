// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { INSUnified } from "./INSUnified.sol";
import { INSDomainPrice } from "./INSDomainPrice.sol";
import { INameChecker } from "./INameChecker.sol";
import { INSReverseRegistrar } from "./INSReverseRegistrar.sol";

/**
 * @title IRONRegistrarController
 * @dev Interface for the Registrar Controller contract that manages the registration, renewal, and commitment of RNS
 * names.
 */
interface IRONRegistrarController {
  /// @dev Error: The provided commitment timestamp is too new for registration.
  error CommitmentTooNew(bytes32 commitment);
  /// @dev Error: The provided commitment timestamp is too old for registration.
  error CommitmentTooOld(bytes32 commitment);
  /// @dev Error: The requested name is not available for registration.
  error NameNotAvailable(string name);
  /// @dev Error: The requested duration for registration is too short.
  error DurationTooShort(uint64 duration);
  /// @dev Error: A resolver is required when additional data is supplied during registration.
  error ResolverRequiredWhenDataSupplied();
  /// @dev Error: An unexpired commitment already exists for the given commitment.
  error UnexpiredCommitmentExists(bytes32 commitment);
  /// @dev Error: Insufficient value (RON) provided for registration.
  error InsufficientValue();
  /// @dev Error: The sender is not authorized for the given RNS node.
  error Unauthorized(bytes32 node);
  /// @dev Error: The maximum commitment age is set too low.
  error MaxCommitmentAgeTooLow();
  /// @dev Error: The maximum commitment age is set too high.
  error MaxCommitmentAgeTooHigh();
  /// @dev Thrown when some one requests for protected names
  error ErrRequestedForProtectedName(string name);
  /// @dev Thrown when received invalid params for registering protected name
  error ErrInvalidRegisterProtectedName(string name, address requestOwner, bool nameProtected, bool ownerWhitelisted);
  /// @dev Thrown when received invalid array length
  error InvalidArrayLength();
  /// @dev Thrown when treasury address is set to null
  error NullAddress();
  /// @dev Thrown when the names is not sorted in ascending order
  error InvalidOrderOfNames();

  /**
   * @dev Emitted when the min registration duration is updated.
   * @param operator The address of the operator who triggered the update.
   * @param duration The new duration in seconds.
   */
  event MinRegistrationDurationUpdated(address indexed operator, uint256 duration);

  /// @dev Emitted when the treasury is updated.
  event TreasuryUpdated(address indexed addr);

  /**
   * @dev Emitted when RNSDomainPrice contract is updated.
   * @param operator The address of the operator who triggered the update.
   * @param newDomainPrice The new duration domain price contract.
   */
  event DomainPriceUpdated(address indexed operator, INSDomainPrice newDomainPrice);

  /**
   * @dev Emitted when the commitment age range is updated.
   * @param operator The address of the operator who triggered the update.
   * @param minCommitmentAge The new minimum commitment age in seconds.
   * @param maxCommitmentAge The new maximum commitment age in seconds.
   */
  event CommitmentAgeUpdated(address indexed operator, uint256 minCommitmentAge, uint256 maxCommitmentAge);

  /**
   * @dev Emitted when a new name is successfully registered.
   * @param name The registered name.
   * @param id The namehash of the registered name.
   * @param owner The owner of the registered name.
   * @param ronPrice The cost of the registration in RON.
   * @param usdPrice The cost of the registration in USD.
   * @param expires The expiration timestamp of the registration.
   */
  event NameRegistered(
    string name, uint256 indexed id, address indexed owner, uint256 ronPrice, uint256 usdPrice, uint64 expires
  );

  /**
   * @dev Emitted when a name is renewed.
   * @param name The renewed name.
   * @param id The namehash of the registered name.
   * @param cost The cost of renewal.
   * @param expires The new expiration timestamp after renewal.
   */
  event NameRenewed(string name, uint256 indexed id, uint256 cost, uint64 expires);

  /**
   * @dev Emitted the whitelist status is updated for the owners of the protected names.
   * @param operator The address of the operator who triggered the update.
   */
  event ProtectedNamesWhitelisted(address indexed operator, uint256[] ids, address[] owners, bool status);

  /**
   * @dev Retrieves the rent price for a given name and duration.
   * @param name The name for which to calculate the rent price.
   * @param duration The duration of the rent.
   * @return usdPrice rent price in usd.
   * @return ronPrice rent price in ron.
   */
  function rentPrice(string memory name, uint64 duration) external view returns (uint256 usdPrice, uint256 ronPrice);

  /**
   * @dev Calculate the corresponding id given RON_ID and name.
   */
  function computeId(string memory name) external pure returns (uint256 id);

  /**
   * @dev Checks if a name is valid.
   * @param name The name to check validity for.
   * @return A boolean indicating whether the name is available.
   */
  function valid(string memory name) external view returns (bool);

  /**
   * @dev Checks if a name is available for registration.
   * @param name The name to check availability for.
   * @return A boolean indicating whether the name is available.
   */
  function available(string memory name) external returns (bool);

  /**
   * @dev Generates the commitment hash for a registration.
   * @param name The name to be registered.
   * @param owner The owner of the name.
   * @param duration The duration of the registration.
   * @param secret The secret used for the commitment.
   * @param resolver The resolver contract address.
   * @param data Additional data associated with the registration.
   * @param reverseRecord Whether to use reverse record for additional data.
   * @return The commitment hash.
   */
  function computeCommitment(
    string memory name,
    address owner,
    uint64 duration,
    bytes32 secret,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) external view returns (bytes32);

  /**
   * @dev Commits to a registration using the commitment hash.
   * @param commitment The commitment hash.
   */
  function commit(bytes32 commitment) external;

  /**
   * @dev Registers a new name.
   * @param name The name to be registered.
   * @param owner The owner of the name.
   * @param duration The duration of the registration.
   * @param secret The secret used for the commitment.
   * @param resolver The resolver contract address.
   * @param data Additional data associated with the registration.
   * @param reverseRecord Whether to use reverse record for additional data.
   */
  function register(
    string calldata name,
    address owner,
    uint64 duration,
    bytes32 secret,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) external payable;

  /**
   * @dev Renews an existing name registration.
   * @param name The name to be renewed.
   * @param duration The duration of the renewal.
   */
  function renew(string calldata name, uint64 duration) external payable;

  /**
   * @dev Renew multiple names in a single transaction.
   * Requirements:
   * - `names` and `duration` arrays must have the same length.
   * - The caller must provide enough value to cover the total renewal cost.
   * - `names` must be sorted in ascending order.
   * @param names The array of names to be renewed.
   * @param durations The array of durations for the renewal.
   */
  function bulkRenew(string[] calldata names, uint64[] calldata durations) external payable;

  /**
   * @dev Registers a protected name.
   *
   * Requirements:
   * - The owner is whitelisted for registering.
   */
  function registerProtectedName(
    string memory name,
    address owner,
    uint64 duration,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) external payable;

  /**
   * @dev Updates min registration duration.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function setMinRegistrationDuration(uint256 duration) external;

  /**
   * @dev Sets the minimum and maximum commitment ages.
   *
   * Requirements:
   * - Caller must have the DEFAULT_ADMIN_ROLE.
   * - The `maxCommitmentAge` must be less than or equal to the current block timestamp.
   * - The `maxCommitmentAge` must be greater than the `minCommitmentAge`.
   *
   * Emits a {CommitmentAgeUpdated} event indicating the successful update of the age range.
   *
   * @param minCommitmentAge The minimum commitment age in seconds.
   * @param maxCommitmentAge The maximum commitment age in seconds.
   */
  function setCommitmentAge(uint256 minCommitmentAge, uint256 maxCommitmentAge) external;

  /**
   * @dev Bulk (de)whitelist for buying protected names.
   *
   * Requirements:
   * - The method caller is contract operator.
   *
   * Emits an event {ProtectedNamesWhitelisted}.
   */
  function bulkWhitelistProtectedNames(uint256[] calldata ids, address[] calldata owners, bool status) external;

  /**
   * @dev Returns the whitelist status for registering protected name.
   */
  function getWhitelistProtectedNameStatus(uint256 id, address owner) external view returns (bool status);

  /**
   * @dev Updates treasury address.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function setTreasury(address payable) external;

  /**
   * @dev Updates price oracle address.
   *
   * Requirements:
   * - The caller must have the admin role.
   */
  function setPriceOracle(INSDomainPrice) external;

  /**
   * @dev Returns the treasury address.
   */
  function getTreasury() external view returns (address);

  /**
   * @dev Pauses the registrar controller's functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function pause() external;

  /**
   * @dev Unpauses the registrar controller's functionality.
   *
   * Requirements:
   * - The caller must have the admin role.
   *
   */
  function unpause() external;

  /**
   * @dev Returns the role identifier for the pauser role.
   */
  function PAUSER_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns the operator role.
   */
  function OPERATOR_ROLE() external pure returns (bytes32);

  /**
   * @dev Returns the threshold for valid name length.
   */
  function MIN_DOMAIN_LENGTH() external view returns (uint8);

  /**
   * @dev Returns the minimum registration duration.
   */
  function getMinRegistrationDuration() external view returns (uint256);

  /**
   * @dev Returns the range of commitment ages allowed.
   */
  function getCommitmentAgeRange() external view returns (uint256 minCommitmentAge, uint256 maxCommitmentAge);

  /**
   * @dev Returns the INSUnified contract associated with this controller.
   */
  function getRNSUnified() external view returns (INSUnified);

  /**
   * @dev Returns the INSDomainPrice contract associated with this controller.
   */
  function getPriceOracle() external view returns (INSDomainPrice);

  /**
   * @dev Returns the INameChecker contract associated with this controller.
   */
  function getNameChecker() external view returns (INameChecker);

  /**
   * @dev Returns the IReverseRegistrar contract associated with this controller.
   */
  function getReverseRegistrar() external view returns (INSReverseRegistrar);
}
