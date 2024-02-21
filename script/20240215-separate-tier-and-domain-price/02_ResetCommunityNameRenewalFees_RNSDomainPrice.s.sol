// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { INSDomainPrice, RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { Contract } from "../utils/Contract.sol";
import "./20240215_Migration.s.sol";

contract Migration__02_ResetCommunityNamesRenewalFees_RNSDomainPrice is Migration__20240215 {
  bytes32[] internal _lbHashes;

  function run() external {
    RNSDomainPrice rnsDomainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));

    _lbHashes = toLabelHashes(_labels);

    address overrider = rnsDomainPrice.getRoleMember(rnsDomainPrice.OVERRIDER_ROLE(), 0);
    uint256 batchSize = 100;
    uint256 totalBatches = (_lbHashes.length + batchSize - 1) / batchSize;

    for (uint256 batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      uint256 startIndex = batchIndex * batchSize;
      uint256 endIndex = startIndex + batchSize;
      if (endIndex > _lbHashes.length) {
        endIndex = _lbHashes.length;
      }

      bytes32[] memory batchLbHashes = new bytes32[](endIndex - startIndex);
      uint256[] memory batchRenewalFees = new uint256[](endIndex - startIndex);

      for (uint256 i = startIndex; i < endIndex; i++) {
        batchLbHashes[i - startIndex] = _lbHashes[i];
        batchRenewalFees[i - startIndex] = type(uint256).max;
      }

      vm.broadcast(overrider);
      rnsDomainPrice.bulkOverrideRenewalFees(batchLbHashes, batchRenewalFees);
    }
  }

  function _postCheck() internal override logFn("_postChecking ...") {
    RNSDomainPrice rnsDomainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));

    for (uint256 i; i < _lbHashes.length; ++i) {
      vm.expectRevert(INSDomainPrice.RenewalFeeIsNotOverriden.selector);
      uint256 overridenRenewalFee = rnsDomainPrice.getOverriddenRenewalFee(_labels[i]);
    }
  }
}
