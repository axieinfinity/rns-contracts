// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 } from "forge-std/console2.sol";
import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { JSONParserLib } from "solady/utils/JSONParserLib.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";
import { LibRNSDomain, RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";

contract Migration__20231106_SubmitReservedNames is RNSDeploy {
  using JSONParserLib for *;
  using JSONParserLib for JSONParserLib.Item;

  function run() public {
    string memory raw = vm.readFile("script/20231106-script/data/mock.json");
    console2.log("raw", raw);
    JSONParserLib.Item memory reservedNames = raw.parse().at('"reservedNames"');
    uint256 length = reservedNames.size();

    console2.log("length", length);

    address[] memory tos = new address[](length);
    string[] memory labels = new string[](length);

    for (uint256 i; i < length; ++i) {
      tos[i] = vm.parseAddress(reservedNames.at(i).at('"address"').value().decodeString());
      labels[i] = reservedNames.at(i).at('"label"').value().decodeString();

      console2.log("tos:", i, tos[i]);
      console2.log("labels:", i, labels[i]);
    }

    uint64 duration = uint64(365 days);
    OwnedMulticaller multicall = new OwnedMulticallerDeploy().run();
    RNSUnified rns = RNSUnified(_config.getAddressFromCurrentNetwork(ContractKey.RNSUnified));
    address resolver = _config.getAddressFromCurrentNetwork(ContractKey.PublicResolver);

    address ronOwner = rns.ownerOf(LibRNSDomain.RON_ID);

    vm.startBroadcast(ronOwner);
    rns.approve(address(multicall), LibRNSDomain.RON_ID);
    multicall.multiMint(rns, LibRNSDomain.RON_ID, resolver, duration, tos, labels);
    vm.stopBroadcast();
  }
}
