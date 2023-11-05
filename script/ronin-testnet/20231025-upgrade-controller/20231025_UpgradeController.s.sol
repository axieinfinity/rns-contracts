// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, TestnetRNSMigration } from "../TestnetRNSMigration.s.sol";

contract Migration__20231025_UpgradeController is TestnetRNSMigration {
  function run() public {
    _upgradeProxy(Contract.RONRegistrarController.key(), EMPTY_ARGS);
  }
}
