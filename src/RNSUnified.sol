// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC721State, IERC721, ERC721, INSUnified, RNSToken } from "./RNSToken.sol";
import { LibSafeRange } from "./libraries/math/LibSafeRange.sol";
import { ModifyingField, LibModifyingField } from "./libraries/LibModifyingField.sol";
import { ALL_FIELDS_INDICATOR, IMMUTABLE_FIELDS_INDICATOR, ModifyingIndicator } from "./types/ModifyingIndicator.sol";

contract RNSUnified is Initializable, RNSToken {
  using LibModifyingField for ModifyingField;

  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
  bytes32 public constant RESERVATION_ROLE = keccak256("RESERVATION_ROLE");
  bytes32 public constant PROTECTED_SETTLER_ROLE = keccak256("PROTECTED_SETTLER_ROLE");
  uint64 public constant MAX_EXPIRY = type(uint64).max;

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  uint64 internal _gracePeriod;
  /// @dev Mapping from token id => records
  mapping(uint256 => Record) internal _recordOf;

  modifier onlyAuthorized(uint256 id, ModifyingIndicator indicator) {
    _requireAuthorized(id, indicator);
    _;
  }

  constructor() payable ERC721("", "") {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address pauser,
    address controller,
    address protectedSettler,
    uint64 gracePeriod,
    string calldata baseTokenURI
  ) external initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(PAUSER_ROLE, pauser);
    _grantRole(CONTROLLER_ROLE, controller);
    _grantRole(PROTECTED_SETTLER_ROLE, protectedSettler);

    _setBaseURI(baseTokenURI);
    _setGracePeriod(gracePeriod);

    _mint(admin, 0x00);
  }

  /// @inheritdoc INSUnified
  function available(uint256 id) public view returns (bool) {
    return block.timestamp > LibSafeRange.add(_expiry(id), _gracePeriod);
  }

  /// @inheritdoc INSUnified
  function getGracePeriod() external view returns (uint64) {
    return _gracePeriod;
  }

  /// @inheritdoc INSUnified
  function setGracePeriod(uint64 gracePeriod) external whenNotPaused onlyRole(CONTROLLER_ROLE) {
    _setGracePeriod(gracePeriod);
  }

  /// @inheritdoc INSUnified
  function mint(uint256 parentId, string calldata label, address resolver, uint64 ttl, address owner, uint64 duration)
    external
    whenNotPaused
    returns (uint64 expiryTime, uint256 id)
  {
    if (!_checkOwnerRules(_msgSender(), parentId)) revert Unauthorized();

    bytes32 labelHash = keccak256(bytes(label));
    id = uint256(keccak256(abi.encode(parentId, labelHash)));
    if (!available(id)) revert Unavailable();

    if (_exists(id)) _burn(id);
    _mint(owner, id);

    expiryTime = uint64(LibSafeRange.addWithUpperbound(block.timestamp, duration, MAX_EXPIRY));
    Record memory record;
    record.mut = MutableRecord({ resolver: resolver, ttl: ttl, owner: owner, expiry: expiryTime, protected: false });
    record.immut = ImmutableRecord({ depth: _recordOf[parentId].immut.depth + 1, parentId: parentId, label: label });

    _recordOf[id] = record;
    emit RecordsUpdated(id, ALL_FIELDS_INDICATOR, record);
  }

  /// @inheritdoc INSUnified
  function getRecords(uint256 id) external view returns (Record memory records, string memory domain) {
    records = _recordOf[id];
    records.mut.expiry = _expiry(id);
    domain = _getDomain(records.immut.parentId, records.immut.label);
  }

  /// @inheritdoc INSUnified
  function reclaim(uint256 id, address owner)
    external
    whenNotPaused
    onlyAuthorized(id, ModifyingField.Owner.indicator())
  {
    _safeTransfer(_recordOf[id].mut.owner, owner, id, "");
  }

  /// @inheritdoc INSUnified
  function renew(uint256 id, uint64 duration) external whenNotPaused onlyRole(CONTROLLER_ROLE) {
    _setExpiry(id, uint64(LibSafeRange.addWithUpperbound(_recordOf[id].mut.expiry, duration, MAX_EXPIRY)));
  }

  /// @inheritdoc INSUnified
  function setExpiry(uint256 id, uint64 expiry) external whenNotPaused onlyRole(CONTROLLER_ROLE) {
    _setExpiry(id, expiry);
  }

  /// @inheritdoc INSUnified
  function bulkSetProtected(uint256[] calldata ids, bool protected) external onlyRole(PROTECTED_SETTLER_ROLE) {
    ModifyingIndicator indicator = ModifyingField.Protected.indicator();
    uint256 id;
    Record memory record;
    record.mut.protected = protected;

    for (uint256 i; i < ids.length;) {
      id = ids[i];
      if (_recordOf[id].mut.protected != protected) {
        _recordOf[id].mut.protected = protected;
        emit RecordsUpdated(id, indicator, record);
      }

      unchecked {
        ++i;
      }
    }
  }

  /// @inheritdoc INSUnified
  function setRecords(uint256 id, ModifyingIndicator indicator, MutableRecord calldata mutRecord)
    external
    whenNotPaused
    onlyAuthorized(id, indicator)
  {
    Record memory record;
    _recordOf[id].mut = record.mut = mutRecord;
    emit RecordsUpdated(id, indicator, record);
  }

  /**
   * @inheritdoc IERC721State
   */
  function stateOf(uint256 tokenId) external view virtual override onlyMinted(tokenId) returns (bytes memory) {
    return abi.encode(_recordOf[tokenId], nonces[tokenId], tokenId);
  }

  /// @inheritdoc INSUnified
  function canSetRecords(address requester, uint256 id, ModifyingIndicator indicator)
    public
    view
    returns (bool allowed, bytes4)
  {
    if (indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR)) {
      return (false, CannotSetImmutableField.selector);
    }
    if (indicator.hasAny(ModifyingField.Protected.indicator()) && !hasRole(PROTECTED_SETTLER_ROLE, requester)) {
      return (false, MissingProtectedSettlerRole.selector);
    }
    bool hasControllerRole = hasRole(CONTROLLER_ROLE, requester);
    if (indicator.hasAny(ModifyingField.Expiry.indicator()) && !hasControllerRole) {
      return (false, MissingControllerRole.selector);
    }
    if (
      indicator.hasAny(
        ModifyingField.Resolver.indicator() | ModifyingField.Ttl.indicator() | ModifyingField.Owner.indicator()
      ) && !(hasControllerRole || _checkOwnerRules(requester, id))
    ) {
      return (false, Unauthorized.selector);
    }

    return (true, 0x00);
  }

  /// @dev Override {ERC721-ownerOf}.
  function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
    if (_isExpired(tokenId)) revert Expired();
    return super.ownerOf(tokenId);
  }

  /// @dev Override {ERC721-_isApprovedOrOwner}.
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
    if (_isExpired(tokenId)) return false;
    return super._isApprovedOrOwner(spender, tokenId);
  }

  /**
   * @dev Helper method to check whether the id is expired.
   */
  function _isExpired(uint256 id) internal view returns (bool) {
    return block.timestamp > _expiry(id);
  }

  /**
   * @dev Helper method to calculate expiry time for specific id.
   */
  function _expiry(uint256 id) internal view returns (uint64) {
    if (hasRole(RESERVATION_ROLE, _ownerOf(id))) return MAX_EXPIRY;
    return _recordOf[id].mut.expiry;
  }

  /**
   * @dev Helper method to check whether the address is owner of parent token.
   */
  function _isHierarchyOwner(address spender, uint256 id) internal view returns (bool) {
    address owner;

    while (id != 0) {
      owner = _recordOf[id].mut.owner;
      if (owner == spender) return true;
      id = _recordOf[id].immut.parentId;
    }

    return false;
  }

  /**
   * @dev Returns whether the owner rules is satisfied.
   * Returns true only if the spender is owner, or approved spender, or owner of parent token.
   */
  function _checkOwnerRules(address spender, uint256 id) internal view returns (bool) {
    return _isApprovedOrOwner(spender, id) || _isHierarchyOwner(spender, id);
  }

  /**
   * @dev Helper method to ensure msg.sender is authorized to modify records of the token id.
   */
  function _requireAuthorized(uint256 id, ModifyingIndicator indicator) internal view {
    (bool allowed, bytes4 errorCode) = canSetRecords(_msgSender(), id, indicator);
    if (!allowed) {
      assembly ("memory-safe") {
        mstore(0x00, errorCode)
        revert(0x1c, 0x04)
      }
    }
  }

  /**
   * @dev Helper method to get full domain name from parent id and current label.
   */
  function _getDomain(uint256 parentId, string memory label) internal view returns (string memory domain) {
    if (parentId == 0) return "";
    domain = label;

    while (parentId != 0) {
      domain = string.concat(domain, ".", _recordOf[parentId].immut.label);
      parentId = _recordOf[parentId].immut.parentId;
    }
  }

  /**
   * @dev Helper method to set expiry time of a token.
   *
   * Requirement:
   * - The token must be registered or in grace period.
   * - Expiry time must be larger than the old one.
   *
   * Emits an event {RecordsUpdated}.
   */
  function _setExpiry(uint256 id, uint64 expiry) internal {
    if (available(id)) revert NameMustBeRegisteredOrInGracePeriod();
    if (expiry <= _recordOf[id].mut.expiry) {
      revert ExpiryTimeMustBeLargerThanTheOldOne();
    }
    Record memory record;

    _recordOf[id].mut.expiry = record.mut.expiry = expiry;
    emit RecordsUpdated(id, ModifyingField.Expiry.indicator(), record);
  }

  /**
   * @dev Helper method to set grace period.
   *
   * Emits an event {GracePeriodUpdated}.
   */
  function _setGracePeriod(uint64 gracePeriod) internal {
    _gracePeriod = gracePeriod;
    emit GracePeriodUpdated(_msgSender(), gracePeriod);
  }

  /// @dev Override {ERC721-_afterTokenTransfer}.
  function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal
    virtual
    override
  {
    super._afterTokenTransfer(from, to, firstTokenId, batchSize);

    Record memory record;
    ModifyingIndicator indicator = ModifyingField.Owner.indicator();
    bool shouldUpdateProtected = !hasRole(PROTECTED_SETTLER_ROLE, _msgSender());
    if (shouldUpdateProtected) indicator = indicator | ModifyingField.Protected.indicator();

    for (uint256 id = firstTokenId; id < firstTokenId + batchSize;) {
      _recordOf[id].mut.owner = record.mut.owner = to;
      if (shouldUpdateProtected) {
        _recordOf[id].mut.protected = false;
        emit RecordsUpdated(id, indicator, record);
      }

      unchecked {
        id++;
      }
    }
  }
}
