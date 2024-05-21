// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { JSONParserLib } from "solady/utils/JSONParserLib.sol";
import { Migration, ISharedArgument } from "../Migration.s.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { INSDomainPrice } from "@rns-contracts/interfaces/INSDomainPrice.sol";

contract Migration__20240215 is Migration {
  using JSONParserLib for *;
  using LibRNSDomain for *;

  string internal constant DATA_PATH = "script/data/517 Community names (Tier 1) - _3 characters.json";

  INSDomainPrice.Tier[] internal _tiers;
  string[] internal _labels;

  constructor() { }

  function toLabelHashes(string[] memory labels) internal pure returns (bytes32[] memory) {
    bytes32[] memory hashes = new bytes32[](labels.length);
    for (uint256 i; i < labels.length; ++i) {
      hashes[i] = labels[i].hashLabel();
    }
    return hashes;
  }

  function toNameHashes(string[] memory labels) internal pure returns (uint256[] memory) {
    uint256[] memory hashes = new uint256[](labels.length);
    for (uint256 i; i < labels.length; ++i) {
      hashes[i] = uint256(labels[i].namehash());
    }
    return hashes;
  }

  function _parseData(string memory path)
    internal
    view
    returns (string[] memory labels, INSDomainPrice.Tier[] memory tiers)
  {
    string memory raw = vm.readFile(path);
    JSONParserLib.Item memory communityNames = raw.parse().at('"communityNames"');
    uint256 length = communityNames.size();
    console.log("length", length);

    labels = new string[](length);
    tiers = new INSDomainPrice.Tier[](length);

    for (uint256 i; i < length; ++i) {
      tiers[i] = INSDomainPrice.Tier(uint8(vm.parseUint(communityNames.at(i).at('"tier"').value().decodeString())));
      labels[i] = (communityNames.at(i).at('"domain"').value().decodeString());
    }
  }
}
