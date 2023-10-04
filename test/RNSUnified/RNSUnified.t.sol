// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console2, Test } from "forge-std/Test.sol";
import "@rns-contracts/RNSUnified.sol";

contract RNSUnifiedTest is Test {
  using Strings for *;

  struct MintParam {
    address owner;
    string name;
    address resolver;
    uint64 duration;
  }

  struct Error {
    bool shouldThrow;
    bytes revertMessage;
  }

  uint64 public constant GRACE_PERIOD = 30 days;
  string public constant BASE_URI = "https://example.com/";

  address internal _admin;
  address internal _pauser;
  address internal _proxyAdmin;
  address internal _controller;
  address internal _protectedSettler;

  uint256 internal _ronId;
  Error internal _noError;
  RNSUnified internal _rns;
  uint64 internal _ronExpiry;

  /// @dev state changes variables
  address internal $minter;

  modifier validAccount(address addr) {
    _assumeValidAccount(addr);
    _;
  }

  modifier mintAs(address addr) {
    _assumeValidAccount(addr);
    $minter = addr;
    _;
  }

  function setUp() external {
    _admin = makeAddr("admin");
    _pauser = makeAddr("pauser");
    _controller = makeAddr("controller");
    _proxyAdmin = makeAddr("proxyAdmin");
    _protectedSettler = makeAddr("protectedSettle");

    address logic = address(new RNSUnified());
    _rns = RNSUnified(
      address(
        new TransparentUpgradeableProxy(logic, _proxyAdmin, abi.encodeCall(RNSUnified.initialize, (_admin, _pauser, _controller, _protectedSettler, GRACE_PERIOD, BASE_URI)))
      )
    );

    vm.label(logic, "RNSUnfied::Logic");
    vm.label(address(_rns), "RNSUnfied::Proxy");

    vm.warp(block.timestamp + GRACE_PERIOD + 1 seconds);
    vm.startPrank(_admin);
    (_ronExpiry, _ronId) = _rns.mint(0x00, "ron", address(0), _admin, _rns.MAX_EXPIRY());
    _rns.setApprovalForAll(_controller, true);
    vm.stopPrank();
  }

  function _assumeValidAccount(address addr) private {
    vm.assume(addr != _proxyAdmin);
    assumeAddressIsNot(
      addr, AddressType.NonPayable, AddressType.ForgeAddress, AddressType.ZeroAddress, AddressType.Precompile
    );
  }

  function _mint(uint256 parentId, MintParam memory mintParam, Error memory error)
    internal
    noGasMetering
    validAccount(mintParam.owner)
    returns (uint64 expiry, uint256 id)
  {
    vm.assume(block.timestamp + mintParam.duration < _ronExpiry);

    if (error.shouldThrow) vm.expectRevert(error.revertMessage);
    vm.prank($minter);
    vm.resumeGasMetering();
    (expiry, id) = _rns.mint(parentId, mintParam.name, mintParam.resolver, mintParam.owner, mintParam.duration);
    vm.pauseGasMetering();
    if (!error.shouldThrow) _assert(parentId, id, mintParam);
  }

  function _toId(uint256 parentId, string memory label) internal pure returns (uint256 id) {
    bytes32 labelHash = keccak256(bytes(label));
    id = uint256(keccak256(abi.encode(parentId, labelHash)));
  }

  function _assert(uint256 parentId, uint256 id, MintParam memory mintParam) internal {
    string memory domain = _rns.getDomain(id);
    string memory parentDomain = _rns.getDomain(parentId);
    INSUnified.Record memory record = _rns.getRecord(id);
    INSUnified.Record memory parentRecord = _rns.getRecord(parentId);

    string memory name = mintParam.name;
    assertEq(_rns.ownerOf(id), mintParam.owner);
    assertEq(record.immut.label, name);
    assertEq(record.mut.protected, false);
    assertEq(record.mut.resolver, mintParam.resolver);
    assertEq(record.immut.depth, parentRecord.immut.depth + 1);
    assertEq(domain, string.concat(name, ".", parentDomain));
    assertEq(domain, string.concat(name, ".", parentRecord.immut.label));
    assertEq(_rns.tokenURI(id), string.concat(BASE_URI, address(_rns).toHexString(), "/", id.toString()));
  }
}
