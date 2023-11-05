// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, TestnetRNSMigration } from "../TestnetRNSMigration.s.sol";

contract Migration__20231021_UpgradeDomainPriceAndAuction is TestnetRNSMigration {
  function run() public {
    _upgradeProxy(Contract.RNSAuction.key(), EMPTY_ARGS);
    _upgradeProxy(Contract.RNSDomainPrice.key(), EMPTY_ARGS);
  }
}
