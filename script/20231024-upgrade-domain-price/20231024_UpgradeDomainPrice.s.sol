// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 as console } from "forge-std/console2.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { ISharedArgument, Config__20231024 } from "./20231024_Config.s.sol";

contract Migration__20231024_UpgradeDomainPrice is Config__20231024 {
  function run() public {
    ISharedArgument.SharedParameter memory param = config.sharedArguments();
    _upgradeProxy(Contract.RNSDomainPrice.key());

    console.log("operator", param.operator);
    console.log("overrider", param.overrider);

    RNSDomainPrice domainPrice = RNSDomainPrice(config.getAddressFromCurrentNetwork(Contract.RNSDomainPrice.key()));
    address admin = domainPrice.getRoleMember(0x00, 0);
    bytes32 overriderRole = domainPrice.OVERRIDER_ROLE();
    vm.broadcast(admin);
    domainPrice.grantRole(overriderRole, param.overrider);
  }
}
