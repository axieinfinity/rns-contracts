// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console2, Test } from "forge-std/Test.sol";
import "@rns-contracts/RNSUnified.sol";

abstract contract RNSUnifiedTest is Test {
  using Strings for *;
  using LibModifyingField for *;

  /// @dev Emitted when a base URI is updated.
  event BaseURIUpdated(address indexed operator, string newURI);
  /// @dev Emitted when the grace period for all domain is updated.
  event GracePeriodUpdated(address indexed operator, uint64 newGracePeriod);

  /**
   * @dev Emitted when the record of node is updated.
   * @param indicator The binary index of updated fields. Eg, 0b10101011 means fields at position 1, 2, 4, 6, 8 (right
   * to left) needs to be updated.
   * @param record The updated fields.
   */
  event RecordUpdated(uint256 indexed node, ModifyingIndicator indicator, INSUnified.Record record);

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
  address internal $reclaimer;
  address internal $recordSetter;
  bool internal $mintGasOff;

  mapping(string name => bool used) internal _usedName;
  mapping(bytes4 errorCode => string indentifier) internal _errorIndentifier;

  modifier validAccount(address addr) {
    _assumeValidAccount(addr);
    _;
  }

  modifier mintAs(address addr) {
    _assumeValidAccount(addr);
    $minter = addr;
    _;
  }

  modifier reclaimAs(address addr) {
    _assumeValidAccount(addr);
    $reclaimer = addr;
    _;
  }

  modifier setRecordAs(address addr) {
    _assumeValidAccount(addr);
    $recordSetter = addr;
    _;
  }

  modifier mintGasOff() {
    $mintGasOff = true;
    _;
  }

  function setUp() external {
    _admin = makeAddr("admin");
    _pauser = makeAddr("pauser");
    _controller = makeAddr("controller");
    _proxyAdmin = makeAddr("proxyAdmin");
    _protectedSettler = makeAddr("protectedSettler");

    address logic = address(new RNSUnified());
    _rns = RNSUnified(
      address(
        new TransparentUpgradeableProxy(
          logic,
          _proxyAdmin,
          abi.encodeCall(
            RNSUnified.initialize, (_admin, _pauser, _controller, _protectedSettler, GRACE_PERIOD, BASE_URI)
          )
        )
      )
    );

    vm.label(logic, "RNSUnfied::Logic");
    vm.label(address(_rns), "RNSUnfied::Proxy");

    _errorIndentifier[INSUnified.Unexists.selector] = "Unexists";
    _errorIndentifier[INSUnified.Unauthorized.selector] = "Unauthorized";
    _errorIndentifier[INSUnified.MissingControllerRole.selector] = "MissingControllerRole";
    _errorIndentifier[INSUnified.CannotSetImmutableField.selector] = "CannotSetImmutableField";
    _errorIndentifier[INSUnified.MissingProtectedSettlerRole.selector] = "MissingProtectedSettlerRole";

    vm.warp(block.timestamp + GRACE_PERIOD + 1 seconds);
    vm.startPrank(_admin);
    (_ronExpiry, _ronId) = _rns.mint(0x0, "ron", address(0), _admin, _rns.MAX_EXPIRY());
    _rns.setApprovalForAll(_controller, true);
    vm.stopPrank();
  }

  function _assumeValidAccount(address addr) internal {
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
    require($minter != address(0), "Minter for RNSUnified::mint not set!");
    vm.assume(block.timestamp + mintParam.duration < _ronExpiry);
    if (error.shouldThrow) vm.expectRevert(error.revertMessage);

    if (!$mintGasOff) vm.resumeGasMetering();
    vm.prank($minter);
    (expiry, id) = _rns.mint(parentId, mintParam.name, mintParam.resolver, mintParam.owner, mintParam.duration);
    if (!$mintGasOff) vm.pauseGasMetering();

    if (!error.shouldThrow) _assertMint(parentId, id, mintParam);
  }

  function _mintBulk(MintParam[] calldata mintParams) internal mintGasOff noGasMetering returns (uint256[] memory ids) {
    uint256 ronId = _ronId;
    MintParam memory mintParam;
    Error memory noError = _noError;
    uint256 length = mintParams.length;
    ids = new uint256[](length);

    for (uint256 i; i < length;) {
      mintParam = mintParams[i];
      vm.assume(!_usedName[mintParam.name]);
      (, ids[i]) = _mint(ronId, mintParam, noError);
      _usedName[mintParam.name] = true;

      unchecked {
        ++i;
      }
    }
  }

  function _reclaim(uint256 id, address owner) internal {
    require($reclaimer != address(0), "Reclaimer for RNSUnified::reclaim not set!");
    INSUnified.Record memory emittedRecord;
    emittedRecord.mut.owner = owner;

    vm.expectEmit(address(_rns));
    emit RecordUpdated(id, ModifyingField.Owner.indicator(), emittedRecord);
    vm.prank($reclaimer);
    _rns.reclaim(id, owner);

    assertEq(owner, _rns.ownerOf(id));
    assertEq(owner, _rns.getRecord(id).mut.owner);
  }

  function _setRecord(
    uint256 id,
    ModifyingIndicator indicator,
    INSUnified.MutableRecord memory mutRecord,
    Error memory error
  ) internal {
    require($recordSetter != address(0), "Record Setter for RNSUnified::setRecord not set!");

    INSUnified.MutableRecord memory mutRecordBefore;
    INSUnified.MutableRecord memory mutRecordAfter;
    INSUnified.Record memory filledRecord;

    if (error.shouldThrow) {
      vm.expectRevert(error.revertMessage);
    } else {
      mutRecordBefore = _rns.getRecord(id).mut;
      filledRecord = _fillMutRecord(indicator, mutRecord);
      // vm.expectEmit(address(_rns));
      // emit RecordUpdated(id, indicator, filledRecord);
    }
    vm.prank($recordSetter);
    _rns.setRecord(id, indicator, mutRecord);

    if (!error.shouldThrow) {
      mutRecordAfter = _rns.getRecord(id).mut;
      _assertRecord(id, indicator, filledRecord.mut, mutRecordBefore, mutRecordAfter);
    }
  }

  function _warpToExpire(uint64 expiry) internal {
    vm.warp(block.timestamp + expiry + 1 seconds);
  }

  function _toId(uint256 parentId, string memory label) internal pure returns (uint256 id) {
    bytes32 labelHash = keccak256(bytes(label));
    id = uint256(keccak256(abi.encode(parentId, labelHash)));
  }

  function _fillMutRecord(ModifyingIndicator indicator, INSUnified.MutableRecord memory mutRecord)
    internal
    pure
    returns (INSUnified.Record memory filledRecord)
  {
    if (indicator.hasAny(ModifyingField.Owner.indicator())) {
      filledRecord.mut.owner = mutRecord.owner;
    }
    if (indicator.hasAny(ModifyingField.Resolver.indicator())) {
      filledRecord.mut.resolver = mutRecord.resolver;
    }
    if (indicator.hasAny(ModifyingField.Expiry.indicator())) {
      filledRecord.mut.expiry = mutRecord.expiry;
    }
    if (indicator.hasAny(ModifyingField.Protected.indicator())) {
      filledRecord.mut.protected = mutRecord.protected;
    }
  }

  function _assertRecord(
    uint256 id,
    ModifyingIndicator indicator,
    INSUnified.MutableRecord memory filledMut,
    INSUnified.MutableRecord memory mutRecordBefore,
    INSUnified.MutableRecord memory mutRecordAfter
  ) internal {
    if (indicator.hasAny(ModifyingField.Owner.indicator())) {
      assertEq(mutRecordAfter.owner, filledMut.owner);
      if (mutRecordAfter.expiry >= block.timestamp) {
        assertEq(_rns.ownerOf(id), filledMut.owner);
      }
    } else {
      assertEq(mutRecordBefore.owner, mutRecordAfter.owner);
      if (mutRecordAfter.expiry >= block.timestamp) {
        assertEq(_rns.ownerOf(id), mutRecordBefore.owner);
      }
    }
    if (indicator.hasAny(ModifyingField.Protected.indicator())) {
      assertEq(mutRecordAfter.protected, filledMut.protected);
    } else {
      assertEq(mutRecordAfter.protected, mutRecordBefore.protected);
    }
    if (indicator.hasAny(ModifyingField.Expiry.indicator())) {
      if (mutRecordAfter.expiry >= block.timestamp) {
        if (!_rns.hasRole(_rns.RESERVATION_ROLE(), _rns.ownerOf(id))) {
          assertEq(mutRecordAfter.expiry, filledMut.expiry);
        } else {
          assertEq(mutRecordAfter.expiry, _rns.MAX_EXPIRY());
        }
      }
    } else {
      assertEq(mutRecordAfter.expiry, mutRecordBefore.expiry);
    }
    if (indicator.hasAny(ModifyingField.Resolver.indicator())) {
      assertEq(mutRecordAfter.resolver, filledMut.resolver);
    } else {
      assertEq(mutRecordAfter.resolver, mutRecordBefore.resolver);
    }
  }

  function _assertMint(uint256 parentId, uint256 id, MintParam memory mintParam) internal {
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
    assertEq(domain, string.concat(name, ".", parentDomain), "domain != $`name.{parentDomain})`");
    assertEq(_rns.tokenURI(id), string.concat(BASE_URI, address(_rns).toHexString(), "/", id.toString()));
  }
}
