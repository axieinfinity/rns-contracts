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

contract Migration__01_Revoke_Roles is Migration {
  using Strings for *;
  using LibRNSDomain for string;

  address duke = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
  address multisig = 0x1FF1edE0242317b8C4229fC59E64DD93952019ef;

  RNSUnified internal _rns;
  RNSAuction internal _auction;
  NameChecker internal _nameChecker;
  RNSDomainPrice internal _domainPrice;
  PublicResolver internal _publicResolver;
  RNSReverseRegistrar internal _reverseRegistrar;
  RONRegistrarController internal _ronController;
  OwnedMulticaller internal _ownedMulticaller;

  function run() external onlyOn(DefaultNetwork.RoninMainnet.key()) {
    _rns = RNSUnified(loadContract(Contract.RNSUnified.key()));
    _auction = RNSAuction(loadContract(Contract.RNSAuction.key()));
    _nameChecker = NameChecker(loadContract(Contract.NameChecker.key()));
    _domainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));
    _publicResolver = PublicResolver(loadContract(Contract.PublicResolver.key()));
    _reverseRegistrar = RNSReverseRegistrar(loadContract(Contract.RNSReverseRegistrar.key()));
    _ronController = RONRegistrarController(loadContract(Contract.RONRegistrarController.key()));
    _ownedMulticaller = OwnedMulticaller(loadContract(Contract.OwnedMulticaller.key()));

    address[] memory contracts = new address[](5);
    contracts[0] = address(_domainPrice);
    contracts[1] = address(_ronController);
    contracts[2] = address(_nameChecker);
    contracts[3] = address(_rns);
    contracts[4] = address(_auction);

    vm.startBroadcast(duke);

    // Transfer .ron domain ownership to owned multicaller
    _rns.transferFrom(duke, address(_ownedMulticaller), 0x0);
    _rns.transferFrom(duke, address(_ownedMulticaller), LibRNSDomain.RON_ID);
    _rns.transferFrom(duke, address(_ownedMulticaller), LibRNSDomain.ADDR_REVERSE_ID);

    address[] memory tos = new address[](3);
    bytes[] memory callDatas = new bytes[](3);
    uint256[] memory values = new uint256[](3);

    tos[0] = address(_rns);
    tos[1] = address(_rns);
    tos[2] = address(_rns);

    callDatas[0] = abi.encodeCall(ERC721.setApprovalForAll, (address(_auction), true));
    callDatas[1] = abi.encodeCall(ERC721.setApprovalForAll, (address(_ronController), true));
    callDatas[2] = abi.encodeCall(ERC721.approve, (address(_reverseRegistrar), LibRNSDomain.ADDR_REVERSE_ID));

    values[0] = 0;
    values[1] = 0;
    values[2] = 0;

    _ownedMulticaller.multicall(tos, callDatas, values);

    uint256 length = contracts.length;

    for (uint256 i; i < length; i++) {
      AccessControlEnumerable(contracts[i]).grantRole(0x0, multisig);
      console.log("Duke will renounce his admin roles of contract:", vm.getLabel(contracts[i]), "manually");

      assertTrue(
        AccessControlEnumerable(contracts[i]).getRoleMemberCount(0x0) > 0,
        string.concat("Role is empty", "contract: ", vm.toString(contracts[i]))
      );
    }

    // Duke will do this manually
    // Ownable(loadContract(Contract.OwnedMulticaller.key())).transferOwnership(multisig);
    console.log(
      "Duke will renounce his owner role of contract:",
      vm.getLabel(loadContract(Contract.OwnedMulticaller.key())),
      "manually"
    );
    // Ownable(loadContract(Contract.RNSReverseRegistrar.key())).transferOwnership(multisig);
    console.log(
      "Duke will renounce his owner role of contract:",
      vm.getLabel(loadContract(Contract.RNSReverseRegistrar.key())),
      "manually"
    );

    vm.stopBroadcast();
  }

  function _postCheck() internal virtual override {
    _validateController();
    _validateAuction();
    _validateReverseRegistrar();
  }

  function _validateReverseRegistrar() internal view logFn("validateReverseRegistrar") {
    assertEq(_rns.getApproved(LibRNSDomain.ADDR_REVERSE_ID), address(_reverseRegistrar));
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
}
