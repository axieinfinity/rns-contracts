// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, Network, TestnetRNSMigration } from "../TestnetRNSMigration.s.sol";

abstract contract Config__20231024 is TestnetRNSMigration {
  function _buildMigrationConfig() internal view virtual override returns (Config memory config) {
    config = super._buildMigrationConfig();
    if (network() == Network.RoninTestnet.key()) {
      config.overrider = config.operator;
    } else if (network() == Network.RoninMainnet.key()) {
      revert("Missing CONFIG");
    } else {
      revert("Missing CONFIG");
    }
  }
}
