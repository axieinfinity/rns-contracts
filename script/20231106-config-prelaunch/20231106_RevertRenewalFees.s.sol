// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract } from "script/utils/Contract.sol";
import { ISharedArgument, Migration } from "script/Migration.s.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";

contract Migration__20231106_RevertRenewalFees is Migration {
  function run() public {
    RNSDomainPrice domainPrice = RNSDomainPrice(config.getAddressFromCurrentNetwork(Contract.RNSDomainPrice.key()));

    ISharedArgument.SharedParameter memory param = config.sharedArguments();
    vm.broadcast(domainPrice.getRoleMember(domainPrice.DEFAULT_ADMIN_ROLE(), 0));
    domainPrice.setRenewalFeeByLengths(param.renewalFees);
  }
}
