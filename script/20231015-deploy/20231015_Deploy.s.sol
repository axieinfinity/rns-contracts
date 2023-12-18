// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { Contract } from "script/utils/Contract.sol";
import {
  RONRegistrarController, RONRegistrarControllerDeploy
} from "script/contracts/RONRegistrarControllerDeploy.s.sol";
import { RNSUnified, RNSUnifiedDeploy } from "script/contracts/RNSUnifiedDeploy.s.sol";
import { RNSAuction, RNSAuctionDeploy } from "script/contracts/RNSAuctionDeploy.s.sol";
import { NameChecker, NameCheckerDeploy } from "script/contracts/NameCheckerDeploy.s.sol";
import { RNSDomainPrice, RNSDomainPriceDeploy } from "script/contracts/RNSDomainPriceDeploy.s.sol";
import { PublicResolver, PublicResolverDeploy } from "script/contracts/PublicResolverDeploy.s.sol";
import { RNSReverseRegistrar, RNSReverseRegistrarDeploy } from "script/contracts/RNSReverseRegistrarDeploy.s.sol";
import { DefaultNetwork, Migration } from "../Migration.s.sol";
import { INSDomainPrice } from "script/interfaces/ISharedArgument.sol";

contract Migration__20231015_Deploy is Migration {
  using Strings for *;
  using LibRNSDomain for string;

  RNSUnified internal _rns;
  RNSAuction internal _auction;
  NameChecker internal _nameChecker;
  RNSDomainPrice internal _domainPrice;
  PublicResolver internal _publicResolver;
  RNSReverseRegistrar internal _reverseRegistrar;
  RONRegistrarController internal _ronController;

  string[] internal _blacklistedWords;

  function run() public onlyOn(DefaultNetwork.RoninTestnet.key()) {
    _rns = new RNSUnifiedDeploy().run();
    _auction = new RNSAuctionDeploy().run();
    _nameChecker = new NameCheckerDeploy().run();
    _domainPrice = new RNSDomainPriceDeploy().run();
    _reverseRegistrar = new RNSReverseRegistrarDeploy().run();
    _publicResolver = new PublicResolverDeploy().run();
    _ronController = new RONRegistrarControllerDeploy().run();

    address admin = _rns.getRoleMember(_rns.DEFAULT_ADMIN_ROLE(), 0);
    {
      string memory data = vm.readFile("./script/20231015-deploy/data/data.json");
      _blacklistedWords = vm.parseJsonStringArray(data, ".words");
    }
    uint256[] memory packedWords = _nameChecker.packBulk(_blacklistedWords);

    vm.startBroadcast(admin);

    _rns.grantRole(_rns.CONTROLLER_ROLE(), address(_auction));
    _rns.grantRole(_rns.RESERVATION_ROLE(), address(_auction));
    _rns.grantRole(_rns.CONTROLLER_ROLE(), address(_ronController));

    (, uint256 ronId) = _rns.mint(0x0, "ron", address(0), admin, _rns.MAX_EXPIRY());
    (, uint256 reverseId) = _rns.mint(0x0, "reverse", address(0), admin, _rns.MAX_EXPIRY());
    (, uint256 addrReverseId) = _rns.mint(reverseId, "addr", address(0), admin, _rns.MAX_EXPIRY());

    _rns.setApprovalForAll(address(_auction), true);
    _rns.setApprovalForAll(address(_ronController), true);
    _rns.approve(address(_reverseRegistrar), addrReverseId);

    _reverseRegistrar.setDefaultResolver(_publicResolver);
    _nameChecker.setForbiddenWords({ packedWords: packedWords, shouldForbid: true });

    vm.stopBroadcast();

    _validateAuction();
    _validateController();
    _validateDomainPrice();
    _validateReverseRegistrar();
    _validateNameChecker();
    _validateRNSUnified(ronId, addrReverseId);

    console.log(StdStyle.green(unicode"✅ All checks are passed"));
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
    console.log(unicode"✅ Controller checks are passed");
  }

  function _validateRNSUnified(uint256 ronId, uint256 addrReverseId) internal logFn("validateRNSUnified") {
    assertEq(ronId, LibRNSDomain.RON_ID);
    assertEq(addrReverseId, LibRNSDomain.ADDR_REVERSE_ID);
    assertTrue(_rns.hasRole(_rns.CONTROLLER_ROLE(), address(_auction)), "grant controller role failed");
    assertTrue(_rns.hasRole(_rns.RESERVATION_ROLE(), address(_auction)), "grant reservation role failed");
    assertEq(address(_ronController.getPriceOracle()), address(_domainPrice), "set price oracle failed");

    console.log(unicode"✅ RNSUnified checks are passed");
  }

  function _validateReverseRegistrar() internal logFn("validateReverseRegistrar") {
    assertEq(_rns.getApproved(LibRNSDomain.ADDR_REVERSE_ID), address(_reverseRegistrar));
  }

  function _validateAuction() internal logFn("validateAuction") {
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

    console.log(unicode"✅ Auction checks are passed");
  }

  function _validateDomainPrice() internal logFn("validateDomainPrice") {
    address operator = _domainPrice.getRoleMember(_domainPrice.OPERATOR_ROLE(), 0);
    string memory domainName = "tudo-provip";
    bytes32[] memory lbHashes = new bytes32[](1);
    lbHashes[0] = LibRNSDomain.hashLabel(domainName);
    uint256[] memory overriddenFees = new uint256[](1);
    overriddenFees[0] = 1;

    vm.startPrank(operator);

    {
      (INSDomainPrice.UnitPrice memory basePrice,) = _domainPrice.getRenewalFee(domainName, 365 days);
      assertApproxEqAbs(basePrice.usd, 5e18, 1e16, "get renewal fee failed");
    }
    {
      _domainPrice.bulkOverrideRenewalFees(lbHashes, overriddenFees);
      (INSDomainPrice.UnitPrice memory basePrice,) = _domainPrice.getRenewalFee(domainName, 365 days);
      assertEq(basePrice.usd, 365 days, "get overridden renewal fee failed");
    }
    {
      uint256[] memory setTypes = new uint256[](1);
      uint256[] memory ronPrices = new uint256[](1);
      bytes32[] memory proofHashes = new bytes32[](1);

      ronPrices[0] = _domainPrice.convertUSDToRON(2e18);
      _domainPrice.bulkTrySetDomainPrice(lbHashes, ronPrices, proofHashes, setTypes);
      (uint256 usdPrice,) = _domainPrice.getDomainPrice(domainName);
      assertApproxEqAbs(usdPrice, 2e18, 1e16, "get domain price 1 failed");

      ronPrices[0] = _domainPrice.convertUSDToRON(1e18);
      _domainPrice.bulkTrySetDomainPrice(lbHashes, ronPrices, proofHashes, setTypes);
      (usdPrice,) = _domainPrice.getDomainPrice(domainName);
      assertApproxEqAbs(usdPrice, 2e18, 1e16, "get domain price 2 failed");

      ronPrices[0] = _domainPrice.convertUSDToRON(1e18);
      _domainPrice.bulkSetDomainPrice(lbHashes, ronPrices, proofHashes, setTypes);
      (usdPrice,) = _domainPrice.getDomainPrice(domainName);
      assertApproxEqAbs(usdPrice, 1e18, 1e16, "get domain price 3 failed");
    }

    vm.stopPrank();

    console.log("Tax Raio:", _domainPrice.getTaxRatio());
    console.log("Converting 1 USD (18 decimals) to RON:", _domainPrice.convertUSDToRON(1e18));
    console.log("Converting 1 RON to USD (18 decimals):", _domainPrice.convertRONToUSD(1 ether));
    console.log("Converting 1m USD (18 decimals) to RON:", _domainPrice.convertUSDToRON(1e18 * 1e6));
    console.log("Converting 1m RON to USD (18 decimals):", _domainPrice.convertRONToUSD(1 ether * 1e6));
    console.log(unicode"✅ Domain price checks are passed");
  }

  function _validateNameChecker() internal logFn("validateNameChecker") {
    string[] memory blacklistedWords = _blacklistedWords;
    (uint8 min, uint8 max) = _nameChecker.getWordRange();
    bool valid;
    bool forbidden;
    string memory word;
    uint256 expectedMax;
    uint256 expectedMin = type(uint256).max;

    console.log(StdStyle.blue("Blacklisted words count"), blacklistedWords.length);
    console.log(StdStyle.blue("Word"), "RONRegistrarController::valid()", "NameChecker::forbidden()");
    console.log(StdStyle.blue("Word Range"), string.concat("min: ", min.toString(), " ", "max: ", max.toString()));

    for (uint256 i; i < blacklistedWords.length;) {
      word = blacklistedWords[i];
      expectedMin = Math.min(bytes(word).length, expectedMin);
      expectedMax = Math.max(bytes(word).length, expectedMax);
      valid = _ronController.valid(word);
      forbidden = _nameChecker.forbidden(word);

      if (i % 50 == 0) {
        console.log(StdStyle.blue(word), valid ? unicode"✅" : unicode"❌", forbidden ? unicode"✅" : unicode"❌");
      }

      assertTrue(!valid);
      assertTrue(forbidden);

      unchecked {
        ++i;
      }
    }

    assertEq(min, expectedMin);
    assertEq(max, expectedMax);

    console.log(unicode"✅ NameChecker checks are passed");
  }
}
