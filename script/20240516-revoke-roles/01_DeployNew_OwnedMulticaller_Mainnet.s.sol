// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";

contract Migration__01_DeployNew_OwnedMulticaller is Migration {
  address internal constant TUDO = 0x0Ebf93387093D7b7cDa9a4dE5d558507810af5eD; // TuDo's trezor
  OwnedMulticaller multicall;

  function run() external onlyOn(DefaultNetwork.RoninMainnet.key()) {
    multicall = OwnedMulticaller(new OwnedMulticallerDeploy().overrideArgs(abi.encode(TUDO)).run());
  }

  function _postCheck() internal virtual override {
    assertEq(multicall.owner(), TUDO);
  }
}
