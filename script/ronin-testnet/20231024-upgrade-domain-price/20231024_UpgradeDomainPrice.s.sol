// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 } from "forge-std/console2.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { Contract, Config__20231024 } from "./20231024_Config.s.sol";

contract Migration__20231024_UpgradeDomainPrice is Config__20231024 {
  function run() public {
    Config memory config = getConfig();
    _upgradeProxy(Contract.RNSDomainPrice.key(), EMPTY_ARGS);

    console2.log("operator", config.operator);
    console2.log("overrider", config.overrider);

    RNSDomainPrice domainPrice = RNSDomainPrice(CONFIG.getAddressFromCurrentNetwork(Contract.RNSDomainPrice.key()));
    address admin = domainPrice.getRoleMember(0x00, 0);
    bytes32 overriderRole = domainPrice.OVERRIDER_ROLE();
    vm.broadcast(admin);
    domainPrice.grantRole(overriderRole, config.overrider);
  }
}
