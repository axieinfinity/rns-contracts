// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INameResolver } from "@rns-contracts/interfaces/resolvers/INameResolver.sol";
import { IERC165, IERC181, IReverseRegistrar } from "@rns-contracts/interfaces/IReverseRegistrar.sol";
import { INSUnified } from "@rns-contracts/interfaces/INSUnified.sol";
import { LibStrAddrConvert } from "@rns-contracts/libraries/LibStrAddrConvert.sol";

/**
 * @notice Customized version of RNSReverseRegistrar: https://github.com/ensdomains/ens-contracts/blob/0c75ba23fae76165d51c9c80d76d22261e06179d/contracts/reverseRegistrar/ReverseRegistrar.sol
 * @dev The reverse registrar provides functions to claim a reverse record, as well as a convenience function to
 * configure the record as it's most commonly used, as a way of specifying a canonical name for an address.
 * The reverse registrar is specified in EIP 181 https://eips.ethereum.org/EIPS/eip-181.
 */
contract RNSReverseRegistrar is Initializable, Ownable, IReverseRegistrar {
  /// @dev This controller must equal to IReverseRegistrar.CONTROLLER_ROLE()
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
  /// @dev Value equals to namehash('addr.reverse')
  bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

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
   * @inheritdoc IReverseRegistrar
   */
  function getDefaultResolver() external view returns (INameResolver) {
    return _defaultResolver;
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function getRNSUnified() external view returns (INSUnified) {
    return _rnsUnified;
  }

  /**
   * @inheritdoc IERC165
   */
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == type(IReverseRegistrar).interfaceId || interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC181).interfaceId;
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function setDefaultResolver(INameResolver resolver) external onlyOwner {
    if (address(resolver) == address(0)) revert NullAssignment();
    _defaultResolver = resolver;
    emit DefaultResolverChanged(resolver);
  }

  /**
   * @inheritdoc IERC181
   */
  function claim(address addr) external returns (bytes32) {
    return claimWithResolver(addr, address(_defaultResolver));
  }

  /**
   * @inheritdoc IERC181
   */
  function setName(string memory name) external returns (bytes32 node) {
    return setNameForAddr(_msgSender(), name);
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function getAddress(bytes32 node) external view returns (address) {
    INSUnified.Record memory record = _rnsUnified.getRecord(uint256(node));
    if (record.immut.parentId != uint256(ADDR_REVERSE_NODE)) revert InvalidNode();
    return LibStrAddrConvert.parseAddr(record.immut.label);
  }

  /**
   * @inheritdoc IERC181
   */
  function claimWithResolver(address addr, address resolver) public live onlyAuthorized(addr) returns (bytes32 node) {
    node = _claimWithResolver(addr, resolver);
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function setNameForAddr(address addr, string memory name)
    public
    live
    onlyAuthorized(addr)
    returns (bytes32 node)
  {
    node = computeNode(addr);
    INSUnified rnsUnified = _rnsUnified;
    if (rnsUnified.ownerOf(uint256(node)) != address(this)) {
      bytes32 claimedNode = _claimWithResolver(addr, address(_defaultResolver));
      if (claimedNode != node) revert InvalidNode();
    }

    INSUnified.Record memory record = rnsUnified.getRecord(uint256(node));
    INameResolver(record.mut.resolver).setName(node, name);
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function computeNode(address addr) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, keccak256(bytes(LibStrAddrConvert.toString(addr)))));
  }

  /**
   * @dev Helper method to claim domain hex(addr) + '.addr.reverse' for addr.
   * Emits an event {ReverseClaimed}.
   */
  function _claimWithResolver(address addr, address resolver) internal returns (bytes32 node) {
    string memory stringifiedAddr = LibStrAddrConvert.toString(addr);
    (, uint256 id) =
      _rnsUnified.mint(uint256(ADDR_REVERSE_NODE), stringifiedAddr, resolver, address(this), type(uint64).max);
    node = bytes32(id);
    emit ReverseClaimed(addr, node);
  }

  /**
   * @dev Helper method to ensure the contract can mint or modify domain hex(addr) + '.addr.reverse' for addr.
   */
  function _requireLive() internal view {
    if (_rnsUnified.ownerOf(uint256(ADDR_REVERSE_NODE)) == address(this)) revert InvalidConfig();
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
