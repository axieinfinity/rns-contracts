// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { INSAuction, RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { RNSOperation, RNSOperationDeploy } from "script/contracts/RNSOperationDeploy.s.sol";

contract Migration__20231124_DeployRNSOperation is RNSDeploy {
  using LibRNSDomain for string;

  function run() public trySetUp {
    RNSOperation rnsOperation = new RNSOperationDeploy().run();

    RNSUnified rns = RNSUnified(_config.getAddressFromCurrentNetwork(ContractKey.RNSUnified));
    RNSAuction auction = RNSAuction(_config.getAddressFromCurrentNetwork(ContractKey.RNSAuction));

    address admin = rns.ownerOf(LibRNSDomain.RON_ID);

    vm.broadcast(rnsOperation.owner());
    rnsOperation.transferOwnership(admin);

    vm.startBroadcast(admin);
    rns.setApprovalForAll(address(rnsOperation), true);
    auction.grantRole(auction.OPERATOR_ROLE(), address(rnsOperation));
    rns.grantRole(rns.PROTECTED_SETTLER_ROLE(), address(rnsOperation));
    vm.stopBroadcast();

    _validateBulkMint(rns, rnsOperation);
    _validateBulkSetProtected(rns, rnsOperation);
    _validateReclaimAuctionNames({ rns: rns, auction: auction, rnsOperation: rnsOperation, searchSize: 20 });
  }

  function _validateReclaimAuctionNames(
    RNSUnified rns,
    RNSAuction auction,
    RNSOperation rnsOperation,
    uint256 searchSize
  ) internal logFn("_validateReclaimAuctionNames") {
    INSAuction.DomainAuction[] memory domainAuctions = new INSAuction.DomainAuction[](searchSize);
    uint256[] memory reservedIds = new uint256[](searchSize);
    for (uint256 i; i < searchSize; ++i) {
      reservedIds[i] = rns.tokenOfOwnerByIndex(address(auction), i);
      (domainAuctions[i],) = auction.getAuction(reservedIds[i]);
    }

    uint256 reclaimableAuctionNameId;
    for (uint256 i; i < searchSize; ++i) {
      if (domainAuctions[i].bid.bidder == address(0x0)) {
        reclaimableAuctionNameId = reservedIds[i];
        break;
      }
    }

    address to = makeAddr("to");
    address[] memory tos = new address[](1);
    tos[0] = to;
    string memory label = rns.getRecord(reclaimableAuctionNameId).immut.label;
    console.log("reclaimable auction label", label);
    string[] memory labels = new string[](1);
    labels[0] = label;

    vm.prank(rnsOperation.owner());
    rnsOperation.reclaimUnbiddedNames({tos: tos, labels: labels, allowFailure: false});

    assertEq(rns.ownerOf(reclaimableAuctionNameId), to);
  }

  function _validateBulkMint(RNSUnified rns, RNSOperation rnsOperation) internal logFn("_validateBulkMint") {
    address to = makeAddr("to");
    address[] memory tos = new address[](1);
    tos[0] = to;
    string[] memory labels = new string[](1);
    labels[0] = "tudo-provip-maximum-utra";
    uint64 duration = uint64(3 days);

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkMint(tos, labels, duration);

    uint256 id = uint256(string.concat(labels[0], ".ron").namehash());
    assertEq(rns.ownerOf(id), to);
  }

  function _validateBulkSetProtected(RNSUnified rns, RNSOperation rnsOperation)
    internal
    logFn("_validateBulkSetProtected")
  {
    string[] memory labels = new string[](1);
    labels[0] = "tudo-provip-maximum-utra";

    bool shouldProtect = true;

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkSetProtected(labels, shouldProtect);

    uint256 id = uint256(string.concat(labels[0], ".ron").namehash());
    assertTrue(rns.getRecord(id).mut.protected);

    shouldProtect = false;

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkSetProtected(labels, shouldProtect);

    assertFalse(rns.getRecord(id).mut.protected);
  }
}
