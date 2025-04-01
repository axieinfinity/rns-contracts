// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";

contract Migration__01_DeployNew_OwnedMulticaller_Testnet is Migration {
  address internal constant DUKE = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
  OwnedMulticaller multicall;

  function run() external onlyOn(DefaultNetwork.RoninTestnet.key()) {
    multicall = OwnedMulticaller(new OwnedMulticallerDeploy().overrideArgs(abi.encode(DUKE)).run());
  }

  function _postCheck() internal virtual override {
    assertEq(multicall.owner(), DUKE);
  }
}
