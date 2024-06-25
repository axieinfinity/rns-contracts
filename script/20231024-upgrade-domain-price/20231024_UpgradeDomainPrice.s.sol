// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { ISharedArgument, Config__20231024 } from "./20231024_Config.s.sol";

contract Migration__20231024_UpgradeDomainPrice is Config__20231024 {
  function run() public {
    ISharedArgument.RNSDomainPriceParam memory param = config.sharedArguments().rnsDomainPrice;
    _upgradeProxy(Contract.RNSDomainPrice.key());

    console.log("operator", param.domainPriceOperators[0]);
    console.log("overrider", param.overrider);

    RNSDomainPrice domainPrice = RNSDomainPrice(loadContract(Contract.RNSDomainPrice.key()));
    address admin = domainPrice.getRoleMember(0x00, 0);
    bytes32 overriderRole = domainPrice.OVERRIDER_ROLE();
    vm.broadcast(admin);
    domainPrice.grantRole(overriderRole, param.overrider);
  }
}
