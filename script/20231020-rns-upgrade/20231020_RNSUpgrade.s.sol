// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";

contract Migration__20231020_RNSUpgrade is RNSDeploy {
  function run() public trySetUp {
    _upgradeProxy(ContractKey.RNSUnified, EMPTY_ARGS);
  }
}
