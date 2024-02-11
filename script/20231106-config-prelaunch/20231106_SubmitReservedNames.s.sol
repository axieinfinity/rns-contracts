// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { Contract } from "script/utils/Contract.sol";
import { JSONParserLib } from "solady/utils/JSONParserLib.sol";
import { Migration } from "script/Migration.s.sol";
import { LibRNSDomain, RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";

contract Migration__20231106_SubmitReservedNames is Migration {
  using JSONParserLib for *;

  function run() public {
    // default duration is 1 year
    uint64 duration = uint64(365 days);

    RNSUnified rns = RNSUnified(loadContract(Contract.RNSUnified.key()));
    address resolver = loadContract(Contract.PublicResolver.key());
    OwnedMulticaller multicall = OwnedMulticaller(loadContract(Contract.OwnedMulticaller.key()));

    console.log(loadContract(Contract.OwnedMulticaller.key()));

    // vm.broadcast(rns.ownerOf(LibRNSDomain.RON_ID));
    //
    // rns.setApprovalForAll(address(multicall), true);
    //
    address[] memory tos;
    string[] memory labels;
    (tos, labels) = _parseData("./script/20231106-param-prelaunch/data/finalReservedNames.json");
    mintBatch(multicall, duration, rns, resolver, tos, labels);
  }

  function mintBatch(
    OwnedMulticaller multicall,
    uint64 duration,
    RNSUnified rns,
    address resolver,
    address[] memory tos,
    string[] memory labels
  ) public {
    vm.broadcast(config.getSender());
    multicall.multiMint(rns, LibRNSDomain.RON_ID, resolver, duration, tos, labels);
  }

  function _parseData(string memory path) internal view returns (address[] memory tos, string[] memory labels) {
    string memory raw = vm.readFile(path);
    JSONParserLib.Item memory reservedNames = raw.parse().at('"reservedNames"');
    uint256 length = reservedNames.size();
    console.log("length", length);

    tos = new address[](length);
    labels = new string[](length);

    for (uint256 i; i < length; ++i) {
      tos[i] = vm.parseAddress(reservedNames.at(i).at('"address"').value().decodeString());
      labels[i] = reservedNames.at(i).at('"label"').value().decodeString();

      console.log("tos:", i, tos[i]);
      console.log("labels:", i, labels[i]);
    }
  }
}
