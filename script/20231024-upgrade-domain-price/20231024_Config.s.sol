// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Network, RNSDeploy } from "script/RNSDeploy.s.sol";

abstract contract Config__20231024 is RNSDeploy {
  function _buildMigrationConfig() internal view virtual override returns (Config memory config) {
    config = super._buildMigrationConfig();
    if (_network == Network.RoninTestnet) {
      config.overrider = config.operator;
    } else if (_network == Network.RoninMainnet) {
      revert("Missing config");
    } else {
      revert("Missing config");
    }
  }
}
