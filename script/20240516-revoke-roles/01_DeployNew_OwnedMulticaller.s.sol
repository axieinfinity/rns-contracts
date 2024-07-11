// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";

contract Migration__01_DeployNew_OwnedMulticaller is Migration {
  address internal constant DUKE = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
  OwnedMulticaller multicall;

  function run() external {
    multicall = new OwnedMulticallerDeploy().run();
  }

  function _postCheck() internal virtual override {
    assertEq(multicall.owner(), DUKE);
  }
}
