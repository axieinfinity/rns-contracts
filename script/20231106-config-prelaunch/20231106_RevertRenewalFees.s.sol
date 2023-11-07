// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";

contract Migration__20231106_RevertRenewalFees is RNSDeploy {
  function run() public {
    RNSDomainPrice domainPrice = RNSDomainPrice(_config.getAddressFromCurrentNetwork(ContractKey.RNSDomainPrice));

    Config memory config = getConfig();
    vm.broadcast(domainPrice.getRoleMember(domainPrice.DEFAULT_ADMIN_ROLE(), 0));
    domainPrice.setRenewalFeeByLengths(config.renewalFees);
  }
}
