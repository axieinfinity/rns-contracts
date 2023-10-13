// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@ensdomains/ens-contracts/dnssec-oracle/RRUtils.sol";
import "@rns-contracts/interfaces/resolvers/IDNSRecordResolver.sol";
import "@rns-contracts/interfaces/resolvers/IDNSZoneResolver.sol";
import "./BaseVersion.sol";

abstract contract DNSResolvable is IDNSRecordResolver, IDNSZoneResolver, ERC165, BaseVersion {
  using RRUtils for *;
  using BytesUtils for bytes;

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev The records themselves. Stored as binary RRSETs.
  mapping(
    uint64 version => mapping(bytes32 node => mapping(bytes32 nameHash => mapping(uint16 resource => bytes data)))
  ) private _versionRecord;

  /// @dev Count of number of entries for a given name.  Required for DNS resolvers when resolving wildcards.
  mapping(uint64 version => mapping(bytes32 node => mapping(bytes32 nameHash => uint16 count))) private
    _versionNameEntriesCount;

  /**
   * @dev Zone hashes for the domains. A zone hash is an EIP-1577 content hash in binary format that should point to a
   * resource containing a single zonefile.
   */
  mapping(uint64 version => mapping(bytes32 node => bytes data)) private _versionZonehash;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override(BaseVersion, ERC165) returns (bool) {
    return interfaceID == type(IDNSRecordResolver).interfaceId || interfaceID == type(IDNSZoneResolver).interfaceId
      || super.supportsInterface(interfaceID);
  }

  /**
   * @dev Checks whether a given node has records.
   * @param node the namehash of the node for which to check the records
   * @param name the namehash of the node for which to check the records
   */
  function hasDNSRecords(bytes32 node, bytes32 name) public view virtual returns (bool) {
    return (_versionNameEntriesCount[_recordVersion[node]][node][name] != 0);
  }

  /**
   * @inheritdoc IDNSRecordResolver
   */
  function dnsRecord(bytes32 node, bytes32 name, uint16 resource) public view virtual override returns (bytes memory) {
    return _versionRecord[_recordVersion[node]][node][name][resource];
  }

  /**
   * @inheritdoc IDNSZoneResolver
   */
  function zonehash(bytes32 node) external view virtual override returns (bytes memory) {
    return _versionZonehash[_recordVersion[node]][node];
  }

  /**
   * @dev See {IDNSRecordResolver-setDNSRecords}.
   */
  function _setDNSRecords(bytes32 node, bytes calldata data) internal {
    uint16 resource = 0;
    uint256 offset = 0;
    bytes memory name;
    bytes memory value;
    bytes32 nameHash;
    uint64 version = _recordVersion[node];
    // Iterate over the data to add the resource records
    for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
      if (resource == 0) {
        resource = iter.dnstype;
        name = iter.name();
        nameHash = keccak256(abi.encodePacked(name));
        value = bytes(iter.rdata());
      } else {
        bytes memory newName = iter.name();
        if (resource != iter.dnstype || !name.equals(newName)) {
          _setDNSRRSet(node, name, resource, data, offset, iter.offset - offset, value.length == 0, version);
          resource = iter.dnstype;
          offset = iter.offset;
          name = newName;
          nameHash = keccak256(name);
          value = bytes(iter.rdata());
        }
      }
    }

    if (name.length > 0) {
      _setDNSRRSet(node, name, resource, data, offset, data.length - offset, value.length == 0, version);
    }
  }

  /**
   * @dev See {IDNSZoneResolver-setZonehash}.
   */
  function _setZonehash(bytes32 node, bytes calldata hash) internal {
    uint64 currentRecordVersion = _recordVersion[node];
    bytes memory oldhash = _versionZonehash[currentRecordVersion][node];
    _versionZonehash[currentRecordVersion][node] = hash;
    emit DNSZonehashChanged(node, oldhash, hash);
  }

  /**
   * @dev Helper method to set DNS config.
   *
   * May emit an event {DNSRecordDeleted}.
   * May emit an event {DNSRecordChanged}.
   *
   */
  function _setDNSRRSet(
    bytes32 node,
    bytes memory name,
    uint16 resource,
    bytes memory data,
    uint256 offset,
    uint256 size,
    bool deleteRecord,
    uint64 version
  ) private {
    bytes32 nameHash = keccak256(name);
    bytes memory rrData = data.substring(offset, size);
    if (deleteRecord) {
      if (_versionRecord[version][node][nameHash][resource].length != 0) {
        _versionNameEntriesCount[version][node][nameHash]--;
      }
      delete (_versionRecord[version][node][nameHash][resource]);
      emit DNSRecordDeleted(node, name, resource);
    } else {
      if (_versionRecord[version][node][nameHash][resource].length == 0) {
        _versionNameEntriesCount[version][node][nameHash]++;
      }
      _versionRecord[version][node][nameHash][resource] = rrData;
      emit DNSRecordChanged(node, name, resource, rrData);
    }
  }
}
