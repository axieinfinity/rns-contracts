// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
  /// @dev Emitted whenever a given node/name/resource's RRSET is updated.
  event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
  /// @dev Emitted whenever a given node/name/resource's RRSET is deleted.
  event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);

  /**
   * @dev Set one or more DNS records.  Records are supplied in wire-format.  Records with the same node/name/resource
   * must be supplied one after the other to ensure the data is updated correctly. For example, if the data was
   * supplied:
   *   a.example.com IN A 1.2.3.4
   *   a.example.com IN A 5.6.7.8
   *   www.example.com IN CNAME a.example.com.
   * then this would store the two A records for a.example.com correctly as a single RRSET, however if the data was
   * supplied:
   *   a.example.com IN A 1.2.3.4
   *   www.example.com IN CNAME a.example.com.
   *   a.example.com IN A 5.6.7.8
   * then this would store the first A record, the CNAME, then the second A record which would overwrite the first.
   *
   * Requirements:
   * - The method caller must be a controller, a registrar, the owner in registry contract, or an operator.
   *
   * @param node the namehash of the node for which to set the records
   * @param data the DNS wire format records to set
   */
  function setDNSRecords(bytes32 node, bytes calldata data) external;

  /**
   * @dev Obtain a DNS record.
   * @param node the namehash of the node for which to fetch the record
   * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
   * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
   * @return the DNS record in wire format if present, otherwise empty
   */
  function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}
