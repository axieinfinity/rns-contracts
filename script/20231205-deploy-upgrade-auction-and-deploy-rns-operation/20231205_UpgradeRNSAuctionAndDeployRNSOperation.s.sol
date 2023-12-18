// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { Contract } from "script/utils/Contract.sol";
import { DefaultContract } from "foundry-deployment-kit/utils/DefaultContract.sol";
import { ISharedArgument } from "script/interfaces/ISharedArgument.sol";
import {
  DefaultNetwork,
  Config__Mainnet20231205
} from "script/20231205-deploy-upgrade-auction-and-deploy-rns-operation/20231205_MainnetConfig.s.sol";
import {
  INSAuction,
  RNSAuction,
  RNSUnified,
  Migration__20231123_UpgradeAuctionClaimeUnbiddedNames as UpgradeAuctionScript
} from "script/20231123-upgrade-auction-claim-unbidded-names/20231123_UpgradeAuctionClaimUnbiddedNames.s.sol";
import {
  RNSOperation,
  Migration__20231124_DeployRNSOperation as DeployRNSOperationScript
} from "script/20231124-deploy-rns-operation/20231124_DeployRNSOperation.s.sol";

contract Migration__20231205_UpgradeRNSAuctionAndDeployRNSOperation is Config__Mainnet20231205 {
  function run() public onlyOn(DefaultNetwork.RoninMainnet.key()) {
    ISharedArgument.SharedParameter memory param = config.sharedArguments();

    ProxyAdmin proxyAdmin = ProxyAdmin(config.getAddressFromCurrentNetwork(DefaultContract.ProxyAdmin.key()));
    address rnsAuctionProxy = config.getAddressFromCurrentNetwork(Contract.RNSAuction.key());
    address logic = _deployLogic(Contract.RNSAuction.key());

    vm.prank(proxyAdmin.owner());

    ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(rnsAuctionProxy), logic);

    console.log("RNSAuction Logic is deployed at:", logic);
    _validataBulkClaimUnbiddedNames({ size: 20 });

    // deploy rns operation contract
    new DeployRNSOperationScript().run();
    RNSOperation rnsOperation = RNSOperation(config.getAddressFromCurrentNetwork(Contract.RNSOperation.key()));

    // transfer owner ship for RNSOperation
    vm.broadcast(rnsOperation.owner());
    rnsOperation.transferOwnership(param.rnsOperationOwner);

    assertTrue(rnsOperation.owner() == param.rnsOperationOwner);
  }

  function _validataBulkClaimUnbiddedNames(uint256 size) internal logFn("_validataBulkClaimUnbiddedNames") {
    RNSAuction auction = RNSAuction(config.getAddressFromCurrentNetwork(Contract.RNSAuction.key()));
    RNSUnified rns = RNSUnified(config.getAddressFromCurrentNetwork(Contract.RNSUnified.key()));

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
    uint256 firstFailId = type(uint256).max;
    for (uint256 i; i < domainAuctions.length; ++i) {
      if (domainAuctions[i].bid.bidder != address(0x0)) {
        firstFailId = reservedIds[i];
        break;
      }
    }
    if (firstFailId != type(uint256).max) {
      // !allowFailure
      vm.prank(operator);
      vm.expectRevert(abi.encodeWithSelector(INSAuction.AlreadyBidding.selector, firstFailId));
      claimeds = auction.bulkClaimUnbiddedNames(tos, reservedIds, false);
    }
  }
}
