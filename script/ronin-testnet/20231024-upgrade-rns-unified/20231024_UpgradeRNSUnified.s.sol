// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, TestnetRNSMigration } from "../TestnetRNSMigration.s.sol";

contract Migration__20231024_UpgradeRNSUnified is TestnetRNSMigration {
  function run() public {
    _upgradeProxy(Contract.RNSUnified.key(), EMPTY_ARGS);
  }
}
