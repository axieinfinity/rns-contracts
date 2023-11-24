// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { INSAuction, RNSAuction } from "@rns-contracts/RNSAuction.sol";

contract Migration__20231123_UpgradeAuctionClaimeUnbiddedNames is RNSDeploy {
  function run() public trySetUp {
    _upgradeProxy(ContractKey.RNSAuction, EMPTY_ARGS);
    _validataBulkClaimUnbiddedNames({ size: 20 });
  }

  function _validataBulkClaimUnbiddedNames(uint256 size) internal logFn("_validataBulkClaimUnbiddedNames") {
    RNSAuction auction = RNSAuction(_config.getAddressFromCurrentNetwork(ContractKey.RNSAuction));
    RNSUnified rns = RNSUnified(_config.getAddressFromCurrentNetwork(ContractKey.RNSUnified));

    uint256 auctionBalance = size;
    console.log("auctionBalance", auctionBalance);
    INSAuction.DomainAuction[] memory domainAuctions = new INSAuction.DomainAuction[](auctionBalance);
    uint256[] memory reservedIds = new uint256[](auctionBalance);
    for (uint256 i; i < auctionBalance; ++i) {
      reservedIds[i] = rns.tokenOfOwnerByIndex(address(auction), i);
      (domainAuctions[i],) = auction.getAuction(reservedIds[i]);
      console.log(reservedIds[i], domainAuctions[i].bid.bidder);
    }

    address to = makeAddr("to");
    address[] memory tos = new address[](reservedIds.length);
    for (uint256 i; i < tos.length; ++i) {
      tos[i] = to;
    }

    address operator = auction.getRoleMember(auction.OPERATOR_ROLE(), 0);
    uint256 snapshotId = vm.snapshot();
    // allowFailure
    vm.prank(operator);
    bool[] memory claimeds = auction.bulkClaimUnbiddedNames(tos, reservedIds, true);
    for (uint256 i; i < claimeds.length; ++i) {
      // flag claimed is true if bidder is null
      assertTrue(claimeds[i] == (domainAuctions[i].bid.bidder == address(0x0)));
      if (claimeds[i]) assertEq(rns.ownerOf(reservedIds[i]), to);
    }

    vm.revertTo(snapshotId);
    uint256 firstFailId;
    for (uint256 i; i < domainAuctions.length; ++i) {
      if (domainAuctions[i].bid.bidder != address(0x0)) {
        firstFailId = reservedIds[i];
        break;
      }
    }
    // !allowFailure
    vm.prank(operator);
    vm.expectRevert(abi.encodeWithSelector(INSAuction.AlreadyBidding.selector, firstFailId));
    claimeds = auction.bulkClaimUnbiddedNames(tos, reservedIds, false);
  }
}
