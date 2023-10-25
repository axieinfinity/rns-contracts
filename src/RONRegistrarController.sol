// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IPublicResolver } from "./interfaces/resolvers/IPublicResolver.sol";
import {
  INSUnified,
  INameChecker,
  INSDomainPrice,
  INSReverseRegistrar,
  IRONRegistrarController
} from "./interfaces/IRONRegistrarController.sol";
import { LibString } from "./libraries/LibString.sol";
import { LibRNSDomain } from "./libraries/LibRNSDomain.sol";
import { RONTransferHelper } from "./libraries/transfers/RONTransferHelper.sol";

/**
 * @title RONRegistrarController
 * @notice Customized version of ETHRegistrarController: https://github.com/ensdomains/ens-contracts/blob/45455f1229556ed4f416ef7225d4caea2c1bc0b5/contracts/ethregistrar/ETHRegistrarController.sol
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract RONRegistrarController is
  Pausable,
  Initializable,
  ReentrancyGuard,
  AccessControlEnumerable,
  IRONRegistrarController
{
  using LibString for string;
  using LibRNSDomain for string;

  /// @dev The minimum domain name's length
  uint8 public constant MIN_DOMAIN_LENGTH = 3;
  /// @inheritdoc IRONRegistrarController
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  /// @inheritdoc IRONRegistrarController
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Minimum duration between commitment and registration in second(s).
  uint256 internal _minCommitmentAge;
  /// @dev Maximum duration between commitment and registration in second(s).
  uint256 internal _maxCommitmentAge;
  /// @dev Min registration duration
  uint256 internal _minRegistrationDuration;

  /// @dev The treasury address.
  address payable internal _treasury;
  /// @dev The rns unified contract.
  INSUnified internal _rnsUnified;
  /// @dev The namechecker contract.
  INameChecker internal _nameChecker;
  /// @dev The price oracle.
  INSDomainPrice internal _priceOracle;
  /// @dev The reverse registrar contract.
  INSReverseRegistrar internal _reverseRegistrar;

  /// @dev Mapping from commitment hash => timestamp that commitment made.
  mapping(bytes32 commitment => uint256 timestamp) internal _committedAt;
  /// @dev Mapping id => owner => flag indicating whether the owner is whitelisted to buy protected name
  mapping(uint256 id => mapping(address owner => bool)) internal _protectedNamesWhitelisted;

  modifier onlyAvailable(string memory name) {
    _requireAvailable(name);
    _;
  }

  constructor() payable {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address pauser,
    address payable treasury,
    uint256 maxCommitmentAge,
    uint256 minCommitmentAge,
    uint256 minRegistrationDuration,
    INSUnified rnsUnified,
    INameChecker nameChecker,
    INSDomainPrice priceOracle,
    INSReverseRegistrar reverseRegistrar
  ) external initializer {
    _setupRole(PAUSER_ROLE, pauser);
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    _setPriceOracle(priceOracle);
    _setMinRegistrationDuration(minRegistrationDuration);
    _setCommitmentAge(minCommitmentAge, maxCommitmentAge);

    _treasury = treasury;
    _rnsUnified = rnsUnified;
    _nameChecker = nameChecker;
    _reverseRegistrar = reverseRegistrar;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getMinRegistrationDuration() public view returns (uint256) {
    return _minRegistrationDuration;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function rentPrice(string memory name, uint64 duration) public view returns (uint256 usdPrice, uint256 ronPrice) {
    (INSDomainPrice.UnitPrice memory basePrice, INSDomainPrice.UnitPrice memory tax) =
      _priceOracle.getRenewalFee(name, duration);
    usdPrice = basePrice.usd + tax.usd;
    ronPrice = basePrice.ron + tax.ron;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function valid(string memory name) public view returns (bool) {
    return name.strlen() >= MIN_DOMAIN_LENGTH && !_nameChecker.forbidden(name);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function available(string memory name) public view returns (bool) {
    return valid(name) && _rnsUnified.available(computeId(name));
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function computeCommitment(
    string memory name,
    address owner,
    uint64 duration,
    bytes32 secret,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) public view onlyAvailable(name) returns (bytes32) {
    if (data.length != 0 && resolver == address(0)) revert ResolverRequiredWhenDataSupplied();
    return keccak256(abi.encode(computeId(name), owner, duration, secret, resolver, data, reverseRecord));
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function computeId(string memory name) public pure returns (uint256 id) {
    return LibRNSDomain.toId(LibRNSDomain.RON_ID, name);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function commit(bytes32 commitment) external whenNotPaused {
    if (_committedAt[commitment] + _maxCommitmentAge >= block.timestamp) revert UnexpiredCommitmentExists(commitment);
    _committedAt[commitment] = block.timestamp;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function setMinRegistrationDuration(uint256 duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setMinRegistrationDuration(duration);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function register(
    string memory name,
    address owner,
    uint64 duration,
    bytes32 secret,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) external payable whenNotPaused nonReentrant {
    uint256 id = computeId(name);
    if (_rnsUnified.getRecord(id).mut.protected) revert ErrRequestedForProtectedName(name);

    bytes32 commitHash = computeCommitment({
      name: name,
      owner: owner,
      duration: duration,
      secret: secret,
      resolver: resolver,
      data: data,
      reverseRecord: reverseRecord
    });
    _validateCommitment(duration, commitHash);

    (uint256 usdPrice, uint256 ronPrice) = _handlePrice(name, duration);
    _register(name, owner, duration, resolver, data, reverseRecord, usdPrice, ronPrice);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function renew(string calldata name, uint64 duration) external payable whenNotPaused nonReentrant {
    (, uint256 ronPrice) = rentPrice(name, duration);
    if (msg.value < ronPrice) revert InsufficientValue();
    uint256 remainAmount = msg.value - ronPrice;

    uint256 id = computeId(name);
    uint64 expiryTime = _rnsUnified.renew(id, duration);
    emit NameRenewed(name, id, ronPrice, expiryTime);

    if (remainAmount != 0) RONTransferHelper.safeTransfer(payable(_msgSender()), remainAmount);
    _transferRONToTreasury();
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function registerProtectedName(
    string memory name,
    address owner,
    uint64 duration,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord
  ) external payable whenNotPaused nonReentrant onlyAvailable(name) {
    if (!available(name)) revert NameNotAvailable(name);
    uint256 id = computeId(name);
    bool protected = _rnsUnified.getRecord(id).mut.protected;
    bool whitelisted = _protectedNamesWhitelisted[id][owner];
    if (!protected || !whitelisted) revert ErrInvalidRegisterProtectedName(name, owner, protected, whitelisted);

    (uint256 usdPrice, uint256 ronPrice) = _handlePrice(name, duration);
    _register(name, owner, duration, resolver, data, reverseRecord, usdPrice, ronPrice);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function bulkWhitelistProtectedNames(uint256[] calldata ids, address[] calldata owners, bool status)
    external
    onlyRole(OPERATOR_ROLE)
  {
    uint256 length = ids.length;
    if (length == 0 || length != owners.length) revert InvalidArrayLength();

    for (uint256 i; i < length;) {
      _protectedNamesWhitelisted[ids[i]][owners[i]] = status;

      unchecked {
        ++i;
      }
    }

    emit ProtectedNamesWhitelisted(_msgSender(), ids, owners, status);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getWhitelistProtectedNameStatus(uint256 id, address owner) external view returns (bool status) {
    return _protectedNamesWhitelisted[id][owner];
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function setTreasury(address payable addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _treasury = addr;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function setCommitmentAge(uint256 minCommitmentAge, uint256 maxCommitmentAge) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setCommitmentAge(minCommitmentAge, maxCommitmentAge);
  }

  /**
   * @dev Internal function to update the commitment age range.
   * Requirements:
   * - The `maxCommitmentAge` must be less than or equal to the current block timestamp.
   * - The `maxCommitmentAge` must be greater than the `minCommitmentAge`.
   * Emits a {CommitmentAgeUpdated} event indicating the successful update of the age range.
   * @param minCommitmentAge The minimum commitment age in seconds.
   * @param maxCommitmentAge The maximum commitment age in seconds.
   */
  function _setCommitmentAge(uint256 minCommitmentAge, uint256 maxCommitmentAge) internal {
    if (maxCommitmentAge > block.timestamp) revert MaxCommitmentAgeTooHigh();
    if (maxCommitmentAge <= minCommitmentAge) revert MaxCommitmentAgeTooLow();

    _minCommitmentAge = minCommitmentAge;
    _maxCommitmentAge = maxCommitmentAge;

    emit CommitmentAgeUpdated(_msgSender(), minCommitmentAge, maxCommitmentAge);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function setPriceOracle(INSDomainPrice priceOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setPriceOracle(priceOracle);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getTreasury() external view returns (address) {
    return _treasury;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getCommitmentAgeRange() external view returns (uint256 minCommitmentAge, uint256 maxCommitmentAge) {
    return (_minCommitmentAge, _maxCommitmentAge);
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getRNSUnified() external view returns (INSUnified) {
    return _rnsUnified;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getPriceOracle() external view returns (INSDomainPrice) {
    return _priceOracle;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getNameChecker() external view returns (INameChecker) {
    return _nameChecker;
  }

  /**
   * @inheritdoc IRONRegistrarController
   */
  function getReverseRegistrar() external view returns (INSReverseRegistrar) {
    return _reverseRegistrar;
  }

  /**
   * @dev Validates commitment.
   *
   * Requirements:
   * - The duration must larger than or equal to minimum registration duration.
   * - The passed duration must in a valid range.
   */
  function _validateCommitment(uint64 duration, bytes32 commitment) internal {
    if (duration < _minRegistrationDuration) revert DurationTooShort(duration);

    uint256 passedDuration = block.timestamp - _committedAt[commitment];
    if (passedDuration < _minCommitmentAge) revert CommitmentTooNew(commitment);
    if (_maxCommitmentAge < passedDuration) revert CommitmentTooOld(commitment);

    delete _committedAt[commitment];
  }

  /**
   * @dev Sets minimum registration duration.
   * Emits a {MinRegistrationDurationUpdated} event indicating the successful update of the registration duration.
   */
  function _setMinRegistrationDuration(uint256 duration) internal {
    _minRegistrationDuration = duration;
    emit MinRegistrationDurationUpdated(_msgSender(), duration);
  }

  /**
   * @dev Sets data into resolver address contract.
   */
  function _setRecords(address resolverAddress, uint256 id, bytes[] calldata data) internal {
    IPublicResolver(resolverAddress).multicallWithNodeCheck(bytes32(id), data);
  }

  /**
   * @dev Sets data into reverse registrar.
   */
  function _setReverseRecord(string memory name, address owner) internal {
    _reverseRegistrar.setNameForAddr(owner, string.concat(name, ".ron"));
  }

  /**
   * @dev Helper method to take fee into treasury address.
   */
  function _transferRONToTreasury() internal {
    RONTransferHelper.safeTransfer(_treasury, address(this).balance);
  }

  /**
   * @dev Helper method to take renewal fee of a name.
   */
  function _handlePrice(string memory name, uint64 duration) internal returns (uint256 usdPrice, uint256 ronPrice) {
    (usdPrice, ronPrice) = rentPrice(name, duration);
    if (msg.value < ronPrice) revert InsufficientValue();

    unchecked {
      uint256 remainAmount = msg.value - ronPrice;
      if (remainAmount != 0) RONTransferHelper.safeTransfer(payable(_msgSender()), remainAmount);
    }

    _transferRONToTreasury();
  }

  /**
   * @dev Helper method to register a name for owner.
   *
   * Emits an event {NameRegistered}.
   */
  function _register(
    string memory name,
    address owner,
    uint64 duration,
    address resolver,
    bytes[] calldata data,
    bool reverseRecord,
    uint256 usdPrice,
    uint256 ronPrice
  ) internal {
    (uint64 expiryTime, uint256 id) = _rnsUnified.mint(LibRNSDomain.RON_ID, name, resolver, owner, duration);
    if (data.length != 0) _setRecords(resolver, id, data);
    if (reverseRecord) _setReverseRecord(name, owner);
    emit NameRegistered(name, id, owner, ronPrice, usdPrice, expiryTime);
  }

  /**
   * @dev Helper method to update RNSDomainPrice contract.
   *
   * Emits an event {DomainPriceUpdated}.
   */
  function _setPriceOracle(INSDomainPrice priceOracle) internal {
    _priceOracle = priceOracle;
    emit DomainPriceUpdated(_msgSender(), priceOracle);
  }

  /**
   * @dev Helper method to check if a domain name is available for register.
   */
  function _requireAvailable(string memory name) internal view {
    if (!available(name)) revert NameNotAvailable(name);
  }
}
