// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { LibRNSDomain } from "src/libraries/LibRNSDomain.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { RNSUnified } from "src/RNSUnified.sol";
import { RNSAuction } from "src/RNSAuction.sol";
import { NameChecker } from "src/NameChecker.sol";
import { RNSDomainPrice } from "src/RNSDomainPrice.sol";
import { PublicResolver } from "src/resolvers/PublicResolver.sol";
import { RNSReverseRegistrar } from "src/RNSReverseRegistrar.sol";
import { RONRegistrarController } from "src/RONRegistrarController.sol";
import { OwnedMulticaller } from "src/utils/OwnedMulticaller.sol";
import { INSDomainPrice } from "src/interfaces/INSDomainPrice.sol";
import { OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";
import { ErrorHandler } from "src/libraries/ErrorHandler.sol";
import { EventRange } from "src/libraries/LibEventRange.sol";
import { RNSOperation } from "src/utils/RNSOperation.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { INSAuction } from "src/interfaces/INSAuction.sol";
import { INSDomainPrice } from "src/interfaces/INSDomainPrice.sol";

contract Migration__02_GrantAdminRoleForMultisig_Mainnet is Migration {
  using Strings for *;
  using ErrorHandler for bool;
  using LibRNSDomain for string;

  address duke = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
  address multisig = 0x9d05d1f5b0424f8fde534bc196ffb6dd211d902a;

  RNSUnified internal _rns;
  RNSAuction internal _auction;
  NameChecker internal _nameChecker;
  RNSDomainPrice internal _domainPrice;
  PublicResolver internal _publicResolver;
  RNSReverseRegistrar internal _reverseRegistrar;
  RONRegistrarController internal _ronController;
  OwnedMulticaller internal _ownedMulticaller;
  RNSOperation internal rnsOperation;
  address internal _batchTransfer;

  function run() external onlyOn(DefaultNetwork.RoninMainnet.key()) {
    _rns = RNSUnified(loadContract(Contract.RNSUnified.key()));
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _nameChecker = NameChecker(loadContract(Contract.NameChecker.key()));
    _domainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));
    _publicResolver = PublicResolver(loadContract(Contract.PublicResolver.key()));
    _reverseRegistrar = RNSReverseRegistrar(loadContract(Contract.RNSReverseRegistrar.key()));
    _ronController = RONRegistrarController(loadContract(Contract.RONRegistrarController.key()));
    // Verify: https://app.roninchain.com/address/0x27876429DB2cDDF017DBb63560D0366E4B4E6f8a
    _ownedMulticaller = OwnedMulticaller(0x27876429DB2cDDF017DBb63560D0366E4B4E6f8a);
    _batchTransfer = loadContract(Contract.ERC721BatchTransfer.key());
    // Verify: https://app.roninchain.com/address/0xCD245263eDdEE593a5A66f93f74C58c544957339
    rnsOperation = RNSOperation(0xCD245263eDdEE593a5A66f93f74C58c544957339);

    address[] memory contracts = new address[](5);
    contracts[0] = address(_domainPrice);
    contracts[1] = address(_ronController);
    contracts[2] = address(_nameChecker);
    contracts[3] = address(_rns);
    contracts[4] = address(_auction);

    vm.startBroadcast(duke);
    // Transfer .ron domain ownership to owned multicaller
    uint256[] memory ids = new uint256[](3);
    ids[0] = 0x0;
    ids[1] = LibRNSDomain.RON_ID;
    ids[2] = LibRNSDomain.ADDR_REVERSE_ID;
    _rns.setApprovalForAll(_batchTransfer, true);

    // Bulk transfer .ron domain ownership to owned multicaller
    (bool success, bytes memory returnOrRevertData) = _batchTransfer.call(
      abi.encodeWithSignature("safeBatchTransfer(address,uint256[],address)", _rns, ids, _ownedMulticaller)
    );
    success.handleRevert(returnOrRevertData);

    // Remove approval for batch transfer
    _rns.setApprovalForAll(_batchTransfer, false);
    _rns.setApprovalForAll(address(_auction), false);
    _rns.setApprovalForAll(address(_ronController), false);
    _rns.setApprovalForAll(address(_reverseRegistrar), false);
    // Remove approval for Legacy Owned Multicaller
    // Verify: https://app.roninchain.com/address/0x8975923D01132bEB6c412F827f63D44712726E13
    _rns.setApprovalForAll(0x8975923D01132bEB6c412F827f63D44712726E13, false);
    // Remove approval for Legacy RNS Operation contracts
    _rns.setApprovalForAll(0xCD245263eDdEE593a5A66f93f74C58c544957339, false);
    _rns.setApprovalForAll(0xd9b3CC879113C7ABaa7694d25801bFFD8Fae0F27, false);

    uint256 length = contracts.length;

    for (uint256 i; i < length; i++) {
      AccessControlEnumerable(contracts[i]).grantRole(0x0, multisig);
      console.log("Duke will renounce his admin roles of contract:", vm.getLabel(contracts[i]), "manually");

      assertTrue(
        AccessControlEnumerable(contracts[i]).getRoleMemberCount(0x0) > 1,
        string.concat("Role is empty", "contract: ", vm.toString(contracts[i]))
      );
    }

    console.log("Revoke roles for domain price", 0xAdc6a8fEB5C53303323A1D0280c0a0d5F2e1a14D);
    // Remove another admin roles: https://sky-mavis.slack.com/archives/C06C3HW1HS7/p1712812933009569
    AccessControlEnumerable(address(_domainPrice)).revokeRole(0x0, 0xAdc6a8fEB5C53303323A1D0280c0a0d5F2e1a14D);

    // Remove operator role for RNS Unified
    AccessControlEnumerable(address(_rns)).revokeRole(_rns.PAUSER_ROLE(), duke);
    AccessControlEnumerable(address(_rns)).revokeRole(_rns.PROTECTED_SETTLER_ROLE(), duke);

    // Remove operator role for RNS Auction
    AccessControlEnumerable(address(_auction)).revokeRole(_auction.OPERATOR_ROLE(), duke);
    // Remove operator role for RNS Domain Price
    AccessControlEnumerable(address(_domainPrice)).revokeRole(_domainPrice.OVERRIDER_ROLE(), duke);
    // Remove operator role for RNS Registrar Controller
    AccessControlEnumerable(address(_ronController)).revokeRole(_ronController.OPERATOR_ROLE(), duke);
    AccessControlEnumerable(address(_ronController)).revokeRole(_ronController.PAUSER_ROLE(), duke);

    // Duke will do this manually
    // Ownable(loadContract(Contract.RNSReverseRegistrar.key())).transferOwnership(multisig);
    console.log(
      "Duke will transfer to multisig his owner role of contract:",
      vm.getLabel(loadContract(Contract.RNSReverseRegistrar.key())),
      "manually"
    );

    vm.stopBroadcast();
  }

  function _postCheck() internal virtual override {
    _validateAuction();
    _validateController();
    _validateDomainPrice();

    // Validate Functionalities of RNS Operation contract
    _validateBulkMint();
    _validateOverriddenTiers();
    _validateBulkSetProtected();
    _validateBulkOverrideRenewalFees();
    _validateReclaimAuctionNames({ searchSize: 20 });
  }

  function _validateOverriddenTiers() internal view logFn("_validateOverriddenTiers") {
    string[] memory labels = new string[](5);
    labels[0] = "heidi";
    labels[1] = "luke";
    labels[2] = "sophia";
    labels[3] = "chief";
    labels[4] = "slim";

    for (uint256 i; i < labels.length; ++i) {
      assertEq(
        uint8(_domainPrice.getTier(labels[i])),
        uint8(INSDomainPrice.Tier.Tier1),
        string.concat("invalid tier for _auction label ", labels[i])
      );
    }
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

    assertEq(_domainPrice.getOverriddenRenewalFee(label), Math.mulDiv(yearlyUSDPrices[0], 1 ether, 365 days));
  }

  function _validateReclaimAuctionNames(uint256 searchSize) internal logFn("_validateReclaimAuctionNames") {
    INSAuction.DomainAuction[] memory domainAuctions = new INSAuction.DomainAuction[](searchSize);
    uint256[] memory reservedIds = new uint256[](searchSize);
    for (uint256 i; i < searchSize; ++i) {
      reservedIds[i] = _rns.tokenOfOwnerByIndex(address(_auction), i);
      (domainAuctions[i],) = _auction.getAuction(reservedIds[i]);
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
    string memory label = _rns.getRecord(reclaimableAuctionNameId).immut.label;
    console.log("reclaimable _auction label", label);
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
    assertEq(_rns.ownerOf(id), to);
  }

  function _validateBulkSetProtected() internal logFn("_validateBulkSetProtected") {
    string[] memory labels = new string[](1);
    labels[0] = "tudo-provip-maximum-utra";

    bool shouldProtect = true;

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkSetProtected(labels, shouldProtect);

    uint256 id = uint256(string.concat(labels[0], ".ron").namehash());
    assertTrue(_rns.getRecord(id).mut.protected);

    shouldProtect = false;

    vm.prank(rnsOperation.owner());
    rnsOperation.bulkSetProtected(labels, shouldProtect);

    assertFalse(_rns.getRecord(id).mut.protected);
  }

  function _validateAuction() internal logFn("_validateAuction") {
    address operator = _auction.getRoleMember(_auction.OPERATOR_ROLE(), 0);
    address admin = _auction.getRoleMember(_auction.DEFAULT_ADMIN_ROLE(), 0);

    string[] memory lbs = new string[](3);
    lbs[0] = "liem";
    lbs[1] = "aliem";
    lbs[2] = "dukedepchai";

    vm.prank(operator);
    uint256[] memory ids = _auction.bulkRegister(lbs);

    assembly {
      mstore(ids, 2)
    }

    address[] memory tos = new address[](2);
    tos[0] = duke;
    tos[1] = duke;

    vm.warp(block.timestamp + 10 minutes);
    vm.prank(operator);
    _auction.bulkClaimUnbiddedNames(tos, ids, false);

    assembly {
      mstore(ids, 3)
    }

    EventRange memory eventRange = EventRange(block.timestamp + 10 minutes, block.timestamp + 11 minutes);
    vm.prank(admin);
    bytes32 auctionId = _auction.createAuctionEvent(eventRange);

    uint256[] memory listedIds = new uint256[](1);
    uint256[] memory startingPrices = new uint256[](1);
    startingPrices[0] = 20 ether;
    listedIds[0] = ids[2];

    vm.prank(operator);
    _auction.listNamesForAuction(auctionId, listedIds, startingPrices);

    address userA = makeAddr("userA");
    address userB = makeAddr("userB");

    vm.deal(userA, 100 ether);
    vm.deal(userB, 200 ether);

    vm.warp(block.timestamp + 10 minutes);
    vm.prank(userA, userA);
    _auction.placeBid{ value: 50 ether }(listedIds[0]);
    vm.prank(userB, userB);
    _auction.placeBid{ value: 100 ether }(listedIds[0]);

    vm.warp(block.timestamp + 11 minutes);
    vm.prank(admin);
    _auction.bulkClaimBidNames(listedIds);

    console.log(unicode"✅ Auction checks are passed");
  }

  function _validateController() internal logFn("_validateController") {
    Account memory user = makeAccount("tudo");
    uint64 duration = 30 days;
    bytes32 secret = keccak256("secret");
    string memory domain = "tudo-controller-promax";

    bytes[] memory data;
    bytes32 commitment =
      _ronController.computeCommitment(domain, user.addr, duration, secret, address(_publicResolver), data, true);

    (, uint256 ronPrice) = _ronController.rentPrice(domain, duration);
    console.log("domain price:", ronPrice);
    vm.deal(user.addr, ronPrice);

    vm.startPrank(user.addr);
    _ronController.commit(commitment);
    vm.warp(block.timestamp + 1 hours);
    _ronController.register{ value: ronPrice }(
      domain, user.addr, duration, secret, address(_publicResolver), data, true
    );
    vm.stopPrank();

    uint256 expectedId = uint256(string.concat(domain, ".ron").namehash());
    assertEq(_rns.ownerOf(expectedId), user.addr);

    (, uint256 rentPrice) = _ronController.rentPrice(domain, 365 days);
    vm.deal(user.addr, rentPrice);
    vm.prank(user.addr);
    _ronController.renew{ value: rentPrice }(domain, 365 days);

    console.log(unicode"✅ Controller checks are passed");
  }

  function _validateDomainPrice() internal logFn("_validateDomainPrice") {
    address operator = _auction.getRoleMember(_auction.OPERATOR_ROLE(), 0);
    string[] memory domainNames = new string[](1);
    string memory domainName = "tudo-reserved-provip";
    domainNames[0] = domainName;
    bytes32[] memory lbHashes = new bytes32[](1);
    lbHashes[0] = LibRNSDomain.hashLabel(domainName);
    uint256[] memory setTypes = new uint256[](1);
    uint256[] memory ronPrices = new uint256[](1);
    bytes32[] memory proofHashes = new bytes32[](1);
    ronPrices[0] = _domainPrice.convertUSDToRON(2e18);

    vm.startPrank(operator);

    _auction.bulkRegister(domainNames);
    _domainPrice.bulkSetDomainPrice(lbHashes, ronPrices, proofHashes, setTypes);

    uint256 id = LibRNSDomain.toId(LibRNSDomain.RON_ID, domainNames[0]);
    (, INSDomainPrice.UnitPrice memory tax) = _domainPrice.getRenewalFee(domainName, 365 days);
    assertTrue(tax.usd != 0, "reversed name not have tax");

    vm.stopPrank();

    assertTrue(_auction.reserved(id), "invalid bulkRegister");
    assertEq(_rns.getRecord(id).mut.expiry, _rns.MAX_EXPIRY(), "invalid expiry time");

    console.log(unicode"✅ Domain Price checks are passed");
  }
}
