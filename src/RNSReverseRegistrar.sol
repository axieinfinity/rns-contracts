// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INameResolver } from "./interfaces/resolvers/INameResolver.sol";
import { IERC165, IERC181, INSReverseRegistrar } from "./interfaces/INSReverseRegistrar.sol";
import { INSUnified } from "./interfaces/INSUnified.sol";
import { LibRNSDomain } from "./libraries/LibRNSDomain.sol";

/**
 * @notice Customized version of ReverseRegistrar: https://github.com/ensdomains/ens-contracts/blob/0c75ba23fae76165d51c9c80d76d22261e06179d/contracts/reverseRegistrar/ReverseRegistrar.sol
 * @dev The reverse registrar provides functions to claim a reverse record, as well as a convenience function to
 * configure the record as it's most commonly used, as a way of specifying a canonical name for an address.
 * The reverse registrar is specified in EIP 181 https://eips.ethereum.org/EIPS/eip-181.
 */
contract RNSReverseRegistrar is Initializable, Ownable, INSReverseRegistrar {
  /// @dev This controller must equal to INSReverseRegistrar.CONTROLLER_ROLE()
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;
  /// @dev The rns unified contract.
  INSUnified internal _rnsUnified;
  /// @dev The default resolver.
  INameResolver internal _defaultResolver;

  modifier live() {
    _requireLive();
    _;
  }

  modifier onlyAuthorized(address addr) {
    _requireAuthorized(addr);
    _;
  }

  constructor() payable {
    _disableInitializers();
  }

  function initialize(address admin, INSUnified rnsUnified) external initializer {
    _rnsUnified = rnsUnified;
    _transferOwnership(admin);
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function getDefaultResolver() external view returns (INameResolver) {
    return _defaultResolver;
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function getRNSUnified() external view returns (INSUnified) {
    return _rnsUnified;
  }

  /**
   * @inheritdoc IERC165
   */
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == type(INSReverseRegistrar).interfaceId || interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC181).interfaceId;
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function setDefaultResolver(INameResolver resolver) external onlyOwner {
    if (address(resolver) == address(0)) revert NullAssignment();
    _defaultResolver = resolver;
    emit DefaultResolverChanged(resolver);
  }

  /**
   * @inheritdoc IERC181
   */
  function claim(address addr) external returns (uint256 id) {
    id = claimWithResolver(addr, address(_defaultResolver));
  }

  /**
   * @inheritdoc IERC181
   */
  function setName(string memory name) external returns (uint256 id) {
    id = setNameForAddr(_msgSender(), name);
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function getAddress(uint256 id) external view returns (address) {
    INSUnified.Record memory record = _rnsUnified.getRecord(id);
    if (record.immut.parentId != LibRNSDomain.ADDR_REVERSE_ID) revert InvalidId();
    return LibRNSDomain.parseAddr(record.immut.label);
  }

  /**
   * @inheritdoc IERC181
   */
  function claimWithResolver(address addr, address resolver) public live onlyAuthorized(addr) returns (uint256 id) {
    id = _claimWithResolver(addr, resolver);
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function setNameForAddr(address addr, string memory name) public live onlyAuthorized(addr) returns (uint256 id) {
    id = computeId(addr);
    INSUnified rnsUnified = _rnsUnified;
    if (rnsUnified.ownerOf(id) != address(this)) {
      uint256 claimedId = _claimWithResolver(addr, address(_defaultResolver));
      if (claimedId != id) revert InvalidId();
    }

    INSUnified.Record memory record = rnsUnified.getRecord(id);
    INameResolver(record.mut.resolver).setName(bytes32(id), name);
  }

  /**
   * @inheritdoc INSReverseRegistrar
   */
  function computeId(address addr) public pure returns (uint256 id) {
    id = LibRNSDomain.toId(LibRNSDomain.ADDR_REVERSE_ID, LibRNSDomain.toString(addr));
  }

  /**
   * @dev Helper method to claim domain hex(addr) + '.addr.reverse' for addr.
   * Emits an event {ReverseClaimed}.
   */
  function _claimWithResolver(address addr, address resolver) internal returns (uint256 id) {
    string memory stringifiedAddr = LibRNSDomain.toString(addr);
    (, id) = _rnsUnified.mint(LibRNSDomain.ADDR_REVERSE_ID, stringifiedAddr, resolver, address(this), type(uint64).max);
    emit ReverseClaimed(addr, id);
  }

  /**
   * @dev Helper method to ensure the contract can mint or modify domain hex(addr) + '.addr.reverse' for addr.
   */
  function _requireLive() internal view {
    INSUnified rnsUnified = _rnsUnified;
    uint256 addrReverseId = LibRNSDomain.ADDR_REVERSE_ID;
    address owner = rnsUnified.ownerOf(addrReverseId);
    if (
      owner == address(this) || rnsUnified.getApproved(addrReverseId) == address(this)
        || rnsUnified.isApprovedForAll(owner, address(this))
    ) {
      revert InvalidConfig();
    }
  }

  /**
   * @dev Helper method to ensure addr is authorized for claiming domain hex(addr) + '.addr.reverse' for addr.
   */
  function _requireAuthorized(address addr) internal view {
    address sender = _msgSender();
    INSUnified rnsUnified = _rnsUnified;
    if (!(addr == sender || rnsUnified.hasRole(CONTROLLER_ROLE, sender) || rnsUnified.isApprovedForAll(addr, sender))) {
      revert Unauthorized();
    }
  }
}
