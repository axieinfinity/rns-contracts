// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, TestnetRNSMigration } from "../TestnetRNSMigration.s.sol";

contract Migration__20231024_UpgradeAuction is TestnetRNSMigration {
  function run() public {
    _upgradeProxy(Contract.RNSAuction.key(), EMPTY_ARGS);
  }
}
