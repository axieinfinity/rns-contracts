// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { LibString } from "solady/utils/LibString.sol";
import { DefaultNetwork } from "foundry-deployment-kit/utils/DefaultNetwork.sol";
import { DefaultContract } from "foundry-deployment-kit/utils/DefaultContract.sol";
import { Contract } from "../utils/Contract.sol";
import { INSDomainPrice, RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import "./20240215_Migration.s.sol";

contract Migration__01_UpgradeRNSDomainPriceAndOverrideTierForCommunityNames_RNSDomainPrice is Migration__20240215 {
  using LibString for *;

  RNSDomainPrice internal _domainPrice;
  IMulticall3 internal _multicall;
  bytes32[] internal _lbHashes;

  function run() external {
    _domainPrice = RNSDomainPrice(_upgradeProxy(Contract.RNSDomainPrice.key()));
    _multicall = IMulticall3(loadContract(DefaultContract.Multicall3.key()));

    (_labels, _tiers) = _parseData(DATA_PATH);

    _lbHashes = toLabelHashes(_labels);

    uint256 batchSize = 100;
    uint256 totalElements = _lbHashes.length;
    uint256 totalBatches = (totalElements + batchSize - 1) / batchSize;

    address overrider = _domainPrice.getRoleMember(_domainPrice.OVERRIDER_ROLE(), 0);

    for (uint256 i; i < totalBatches; i++) {
      console.log("Processing batch", i, "of", totalBatches);
      uint256 start = i * batchSize;
      uint256 end = (i + 1) * batchSize;
      if (end > totalElements) {
        end = totalElements;
      }

      bytes32[] memory batchHashes = new bytes32[](end - start);
      INSDomainPrice.Tier[] memory batchTiers = new INSDomainPrice.Tier[](end - start);

      for (uint256 j = start; j < end; j++) {
        batchHashes[j - start] = _lbHashes[j];
        batchTiers[j - start] = _tiers[j];
      }

      vm.broadcast(overrider);
      _domainPrice.bulkOverrideTiers(batchHashes, batchTiers);
    }
  }

  function _postCheck() internal override logFn("_postChecking ...") {
    _validateOverridenTiers();
    _validateOtherDomainTiers();
  }

  function _validateOtherDomainTiers() internal logFn("_validating other domain tiers ...") {
    if (network() == DefaultNetwork.RoninMainnet.key()) {
      assertEq(uint8(_domainPrice.getTier("tudo")), uint8(INSDomainPrice.Tier.Tier2), "invalid tier for tudo");
      assertEq(uint8(_domainPrice.getTier("duke")), uint8(INSDomainPrice.Tier.Tier2), "invalid tier for duke");
      assertEq(uint8(_domainPrice.getTier("ace")), uint8(INSDomainPrice.Tier.Tier1), "invalid tier for ace");
      assertEq(uint8(_domainPrice.getTier("dragon")), uint8(INSDomainPrice.Tier.Tier2), "invalid tier for dragon");
      assertEq(uint8(_domainPrice.getTier("tokuda")), uint8(INSDomainPrice.Tier.Tier3), "invalid tier for tokuda");
      assertEq(uint8(_domainPrice.getTier("metaverse")), uint8(INSDomainPrice.Tier.Tier2), "invalid tier for metaverse");
      assertEq(uint8(_domainPrice.getTier("nuke")), uint8(INSDomainPrice.Tier.Tier2), "invalid tier for nuke");
      assertEq(
        uint8(_domainPrice.getTier("merchandising")), uint8(INSDomainPrice.Tier.Tier3), "invalid tier for merchandising"
      );
    }
  }

  function _validateOverridenTiers() internal logFn("_validating overriden tiers ...") {
    IMulticall3.Call[] memory calls = new IMulticall3.Call[](_lbHashes.length);

    for (uint256 i; i < _lbHashes.length; ++i) {
      calls[i] = IMulticall3.Call({
        target: address(_domainPrice),
        callData: abi.encodeCall(_domainPrice.getTier, (_labels[i]))
      });
    }

    (, bytes[] memory returnData) = _multicall.aggregate(calls);
    INSDomainPrice.Tier[] memory tiers = new INSDomainPrice.Tier[](_lbHashes.length);

    for (uint256 i; i < _lbHashes.length; ++i) {
      tiers[i] = abi.decode(returnData[i], (INSDomainPrice.Tier));
      assertEq(uint8(tiers[i]), uint8(_tiers[i]), string.concat("tier not set", vm.toString(i)));
    }
  }
}
