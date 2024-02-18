// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { LibString } from "solady/utils/LibString.sol";
import { DefaultContract } from "foundry-deployment-kit/utils/DefaultContract.sol";
import { Contract } from "../utils/Contract.sol";
import { INSDomainPrice, RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import "./20240215_Migration.s.sol";

contract Migration__02_UpgradeRNSDomainPriceAndOverrideTierForCommunityNames_RNSDomainPrice is Migration__20240215 {
  using LibString for *;

  RNSDomainPrice internal _domainPrice;
  IMulticall3 internal _multicall;
  bytes32[] internal _lbHashes;

  function run() external {
    _domainPrice = RNSDomainPrice(_upgradeProxy(Contract.RNSDomainPrice.key()));
    _multicall = IMulticall3(loadContract(DefaultContract.Multicall3.key()));

    (_labels, _tiers) = _parseData(DATA_PATH);
    _lbHashes = toLabelHashes(_labels);

    vm.broadcast(_domainPrice.getRoleMember(_domainPrice.OVERRIDER_ROLE(), 0));
    _domainPrice.bulkOverrideTiers(_lbHashes, _tiers);
  }

  function _postCheck() internal override {
    IMulticall3.Call[] memory calls = new IMulticall3.Call[](_lbHashes.length);

    for (uint256 i; i < _lbHashes.length; ++i) {
      calls[i] = IMulticall3.Call({
        target: address(_domainPrice),
        callData: abi.encodeCall(_domainPrice.getTier, (_labels[i]))
      });
    }

    (, bytes[] memory returnData) = _multicall.aggregate(calls);
    uint256[] memory tiers = new uint256[](_lbHashes.length);

    for (uint256 i; i < _lbHashes.length; ++i) {
      tiers[i] = abi.decode(returnData[i], (uint256));
      console.log("label:", _labels[i], "tier:", tiers[i]);
      assertEq(tiers[i], _tiers[i], string.concat("tier not set", vm.toString(i)));
    }
  }
}
