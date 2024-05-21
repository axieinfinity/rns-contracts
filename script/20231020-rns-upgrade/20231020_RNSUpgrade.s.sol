// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20231020_RNSUpgrade is Migration {
  function run() public {
    _upgradeProxy(Contract.RNSUnified.key());
  }
}
