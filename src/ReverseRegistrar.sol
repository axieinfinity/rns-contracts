// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rns-contracts/interfaces/resolvers/INameResolver.sol";
import "@rns-contracts/interfaces/IReverseRegistrar.sol";
import "@rns-contracts/interfaces/INSUnified.sol";
import "@rns-contracts/libraries/LibStrAddrConvert.sol";

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
  bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;
  /// @dev The rns unified contract.
  INSUnified internal _rnsUnified;
  /// @dev The default resolver.
  INameResolver internal _defaultResolver;

  modifier live() {
    require(_rnsUnified.ownerOf(uint256(ADDR_REVERSE_NODE)) == address(this), "RNSReverseRegistrar: invalid config");
    _;
  }

  modifier onlyAuthorized(address addr) {
    require(
      addr == _msgSender() || _rnsUnified.hasRole(CONTROLLER_ROLE, _msgSender())
        || _rnsUnified.isApprovedForAll(addr, _msgSender()),
      "RNSReverseRegistrar: unauthorized sender"
    );
    _;
  }

  constructor() {
    _disableInitializers();
  }

  function initialize(address admin, INSUnified rnsUnified_) external initializer {
    _rnsUnified = rnsUnified_;
    _transferOwnership(admin);
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function defaultResolver() external view override returns (INameResolver) {
    return _defaultResolver;
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function setDefaultResolver(INameResolver resolver) public override onlyOwner {
    require(address(resolver) != address(0), "RNSReverseRegistrar: null assignment");
    _defaultResolver = resolver;
    emit DefaultResolverChanged(resolver);
  }

  /**
   * @inheritdoc IERC181
   */
  function claim(address addr) public override returns (bytes32) {
    return claimWithResolver(addr, address(_defaultResolver));
  }

  /**
   * @inheritdoc IERC181
   */
  function claimWithResolver(address addr, address resolver)
    public
    override
    live
    onlyAuthorized(addr)
    returns (bytes32 node)
  {
    string memory stringifiedAddr = LibStrAddrConvert.toString(addr);
    (, uint256 id) =
      _rnsUnified.mint(uint256(ADDR_REVERSE_NODE), stringifiedAddr, resolver, address(this), type(uint64).max);
    node = bytes32(id);
    emit ReverseClaimed(addr, node);
  }

  /**
   * @inheritdoc IERC181
   */
  function setName(string memory name) public override returns (bytes32 node) {
    return setNameForAddr(_msgSender(), name);
  }

  /**
   * @inheritdoc IReverseRegistrar
   */
  function setNameForAddr(address addr, string memory name)
    public
    override
    live
    onlyAuthorized(addr)
    returns (bytes32 node)
  {
    node = computeNode(addr);
    if (_rnsUnified.ownerOf(uint256(node)) != address(this)) {
      bytes32 claimedNode = _claimWithResolver(addr, address(_defaultResolver));
      require(claimedNode == node, "RNSReverseRegistrar: invalid node");
    }

    INSUnified.Record memory record = _rnsUnified.getRecord(uint256(node));
    INameResolver(record.mut.resolver).setName(node, name);
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
   * @inheritdoc IReverseRegistrar
   */
  function computeNode(address addr) public pure override returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, keccak256(bytes(LibStrAddrConvert.toString(addr)))));
  }
}
