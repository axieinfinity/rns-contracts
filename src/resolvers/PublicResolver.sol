//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IVersionResolver } from "@rns-contracts/interfaces/resolvers/IVersionResolver.sol";
import { Multicallable } from "@rns-contracts/extensions/Multicallable.sol";
import { USER_FIELDS_INDICATOR } from "../types/ModifyingIndicator.sol";
import { ABIResolvable } from "./ABIResolvable.sol";
import { AddressResolvable } from "./AddressResolvable.sol";
import { ContentHashResolvable } from "./ContentHashResolvable.sol";
import { DNSResolvable } from "./DNSResolvable.sol";
import { InterfaceResolvable } from "./InterfaceResolvable.sol";
import { NameResolvable } from "./NameResolvable.sol";
import { PublicKeyResolvable } from "./PublicKeyResolvable.sol";
import { TextResolvable } from "./TextResolvable.sol";
import "@rns-contracts/interfaces/resolvers/IPublicResolver.sol";

/**
 * @title Public Resolver
 * @notice Customized version of PublicResolver: https://github.com/ensdomains/ens-contracts/blob/0c75ba23fae76165d51c9c80d76d22261e06179d/contracts/resolvers/PublicResolver.sol
 * @dev A simple resolver anyone can use, only allows the owner of a node to set its address.
 */
contract PublicResolver is
  IPublicResolver,
  ABIResolvable,
  AddressResolvable,
  ContentHashResolvable,
  DNSResolvable,
  InterfaceResolvable,
  NameResolvable,
  PublicKeyResolvable,
  TextResolvable,
  Multicallable,
  Initializable
{
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev The RNS Unified contract
  INSUnified internal _rnsUnified;

  /// @dev The reverse registrar contract
  INSReverseRegistrar internal _reverseRegistrar;

  modifier onlyAuthorized(bytes32 node) {
    _requireAuthorized(node, msg.sender);
    _;
  }

  constructor() payable {
    _disableInitializers();
  }

  function initialize(INSUnified rnsUnified, INSReverseRegistrar reverseRegistrar) external initializer {
    _rnsUnified = rnsUnified;
    _reverseRegistrar = reverseRegistrar;
  }

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID)
    public
    view
    override(
      ABIResolvable,
      AddressResolvable,
      ContentHashResolvable,
      DNSResolvable,
      InterfaceResolvable,
      NameResolvable,
      PublicKeyResolvable,
      TextResolvable,
      Multicallable
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceID);
  }

  /// @inheritdoc IPublicResolver
  function getRNSUnified() external view returns (INSUnified) {
    return _rnsUnified;
  }

  /// @inheritdoc IPublicResolver
  function getReverseRegistrar() external view returns (INSReverseRegistrar) {
    return _reverseRegistrar;
  }

  /// @inheritdoc IPublicResolver
  function multicallWithNodeCheck(bytes32 node, bytes[] calldata data)
    external
    override
    returns (bytes[] memory results)
  {
    if (node != 0) {
      for (uint256 i; i < data.length;) {
        require(node == bytes32(data[i][4:36]), "PublicResolver: All records must have a matching namehash");
        unchecked {
          ++i;
        }
      }
    }

    return _tryMulticall(true, data);
  }

  /// @inheritdoc IVersionResolver
  function clearRecords(bytes32 node) external onlyAuthorized(node) {
    _clearRecords(node);
  }

  /// @inheritdoc IABIResolver
  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external onlyAuthorized(node) {
    _setABI(node, contentType, data);
  }

  /// @inheritdoc IAddressResolver
  function setAddr(bytes32 node, address addr_) external onlyAuthorized(node) {
    revert("PublicResolver: Cannot set address");
    _setAddr(node, addr_);
  }

  /// @inheritdoc IContentHashResolver
  function setContentHash(bytes32 node, bytes calldata hash) external onlyAuthorized(node) {
    _setContentHash(node, hash);
  }

  /// @inheritdoc IDNSRecordResolver
  function setDNSRecords(bytes32 node, bytes calldata data) external onlyAuthorized(node) {
    _setDNSRecords(node, data);
  }

  /// @inheritdoc IDNSZoneResolver
  function setZonehash(bytes32 node, bytes calldata hash) external onlyAuthorized(node) {
    _setZonehash(node, hash);
  }

  /// @inheritdoc IInterfaceResolver
  function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external onlyAuthorized(node) {
    _setInterface(node, interfaceID, implementer);
  }

  /// @inheritdoc INameResolver
  function setName(bytes32 node, string calldata newName) external onlyAuthorized(node) {
    _setName(node, newName);
  }

  /// @inheritdoc IPublicKeyResolver
  function setPubkey(bytes32 node, bytes32 x, bytes32 y) external onlyAuthorized(node) {
    _setPubkey(node, x, y);
  }

  /// @inheritdoc ITextResolver
  function setText(bytes32 node, string calldata key, string calldata value) external onlyAuthorized(node) {
    _setText(node, key, value);
  }

  /// @inheritdoc IPublicResolver
  function isAuthorized(bytes32 node, address account) public view returns (bool authorized) {
    (authorized,) = _rnsUnified.canSetRecord(account, uint256(node), USER_FIELDS_INDICATOR);
  }

  /// @dev Override {IAddressResolvable-addr}.
  function addr(bytes32 node)
    public
    view
    virtual
    override(AddressResolvable, IAddressResolver, InterfaceResolvable)
    returns (address payable)
  {
    return payable(_rnsUnified.ownerOf(uint256(node)));
  }

  /// @dev Override {INameResolver-name}.
  function name(bytes32 node) public view virtual override(INameResolver, NameResolvable) returns (string memory) {
    address reversedAddress = _reverseRegistrar.getAddress(node);
    string memory domainName = super.name(node);
    uint256 tokenId = uint256(_rnsUnified.namehash(domainName));
    return _rnsUnified.ownerOf(tokenId) == reversedAddress ? domainName : "";
  }

  /**
   * @dev Reverts if the msg sender is not authorized.
   */
  function _requireAuthorized(bytes32 node, address account) internal view {
    require(isAuthorized(node, account), "PublicResolver: unauthorized caller");
  }
}
