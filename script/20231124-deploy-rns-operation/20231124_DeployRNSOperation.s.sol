// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { INSAuction, RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { RNSOperation, RNSOperationDeploy } from "script/contracts/RNSOperationDeploy.s.sol";

contract Migration__20231124_DeployRNSOperation is Migration {
  using LibRNSDomain for string;

  RNSUnified private rns;
  RNSAuction private auction;
  RNSOperation private rnsOperation;
  RNSDomainPrice private domainPrice;

  function run() public {
    rnsOperation = new RNSOperationDeploy().run();

    domainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));
    rns = RNSUnified(loadContract(Contract.RNSUnified.key()));
    auction = RNSAuction(loadContract(Contract.RNSAuction.key()));

    address admin = rns.ownerOf(LibRNSDomain.RON_ID);

    vm.broadcast(rnsOperation.owner());
    rnsOperation.transferOwnership(admin);

    vm.startBroadcast(admin);

    rns.setApprovalForAll(address(rnsOperation), true);
    auction.grantRole(auction.OPERATOR_ROLE(), address(rnsOperation));
    rns.grantRole(rns.PROTECTED_SETTLER_ROLE(), address(rnsOperation));
    domainPrice.grantRole(domainPrice.OVERRIDER_ROLE(), address(rnsOperation));

    vm.stopBroadcast();
  }

  function _postCheck() internal override {
    _validateBulkMint();
    _validateBulkSetProtected();
    _validateBulkOverrideRenewalFees();
    _validateReclaimAuctionNames({ searchSize: 20 });
  }

  function _validateBulkOverrideRenewalFees() internal logFn("_validateBulkOverrideRenewalFees") {
    string memory label = "tudo-provip-maximum-ultra";
    string[] memory labels = new string[](1);
    labels[0] = label;
    uint256[] memory yearlyUSDPrices = new uint256[](1);
    // 10 usd per year
    yearlyUSDPrices[0] = 10;

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkOverrideRenewalFees(labels, yearlyUSDPrices);

    assertEq(domainPrice.getOverriddenRenewalFee(label), Math.mulDiv(yearlyUSDPrices[0], 1 ether, 365 days));
  }

  function _validateReclaimAuctionNames(uint256 searchSize) internal logFn("_validateReclaimAuctionNames") {
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
    rnsOperation.reclaimUnbiddedNames({ tos: tos, labels: labels, allowFailure: false });
  }

  function _validateBulkMint() internal logFn("_validateBulkMint") {
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

  function _validateBulkSetProtected() internal logFn("_validateBulkSetProtected") {
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
