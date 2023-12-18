// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { INSAuction, EventRange, RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20231115_MigrateInvalidAuctionNames is Migration {
  function run() public {
    RNSAuction auction = RNSAuction(config.getAddressFromCurrentNetwork(Contract.RNSAuction.key()));

    uint256[] memory ids = new uint256[](2);
    // namehash`pc.ron`
    ids[0] = 0x601dccd6a440eb22898b2a72036566e9e57f5b7fdfd11c2e2ede7265aec13f45;
    // namehash `ox.ron`
    ids[1] = 0x832f650be9aa2ded8d1a23a429039e3d03abde98c83c2d66d350779253f2ad6d;

    uint256[] memory startingPrices = new uint256[](2);

    // create new auction
    vm.broadcast(auction.getRoleMember(0x0, 0));
    bytes32 auctionId = auction.createAuctionEvent(EventRange(2332515600, 2332515600 + 1 days));

    console.logBytes32(auctionId);

    // relist ids to new auction
    vm.broadcast(auction.getRoleMember(auction.OPERATOR_ROLE(), 0));
    auction.listNamesForAuction(auctionId, ids, startingPrices);

    INSAuction.DomainAuction memory domainAuction;
    (domainAuction,) = auction.getAuction(ids[0]);
    assertEq(domainAuction.auctionId, auctionId);
    (domainAuction,) = auction.getAuction(ids[1]);
    assertEq(domainAuction.auctionId, auctionId);
  }
}
