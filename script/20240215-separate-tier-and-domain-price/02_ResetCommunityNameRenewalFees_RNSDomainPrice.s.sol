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

    uint256[] memory renewalFees = new uint256[](_lbHashes.length);

    address overrider = rnsDomainPrice.getRoleMember(rnsDomainPrice.OVERRIDER_ROLE(), 0);
    vm.startBroadcast(overrider);
    rnsDomainPrice.bulkOverrideRenewalFees(_lbHashes, renewalFees);

    vm.stopBroadcast();
  }

  function _postCheck() internal override logFn("_postChecking ...") {
    RNSDomainPrice rnsDomainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));

    for (uint256 i; i < _lbHashes.length; ++i) {
      (INSDomainPrice.UnitPrice memory renewalFee,) = rnsDomainPrice.getRenewalFee(_labels[i], 1);
      assertEq(renewalFee.usd, 0, "renewal fee not reset");
      assertEq(renewalFee.ron, 0, "renewal fee not reset");
    }
  }
}
