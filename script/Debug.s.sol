// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { RNSDeploy } from "./RNSDeploy.s.sol";
import { ErrorHandler } from "@rns-contracts/libraries/ErrorHandler.sol";

contract Debug is RNSDeploy {
  using ErrorHandler for *;

  function debug(uint256 forkBlock, address from, address to, uint256 value, bytes calldata callData) external {
    if (forkBlock != 0) {
      vm.rollFork(forkBlock);
    }
    vm.prank(from);
    (bool success, bytes memory returnOrRevertData) = to.call{ value: value }(callData);
    success.handleRevert(returnOrRevertData);
  }
}
