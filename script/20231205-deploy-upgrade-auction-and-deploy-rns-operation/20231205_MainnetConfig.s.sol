// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Network, RNSDeploy } from "script/RNSDeploy.s.sol";

abstract contract Config__Mainnet20231205 is RNSDeploy {
  function _buildMigrationConfig() internal view virtual override returns (Config memory config) {
    config = super._buildMigrationConfig();
    if (_network == Network.RoninMainnet) {
      config.rnsOperationOwner = 0x1FF1edE0242317b8C4229fC59E64DD93952019ef;
    } else {
      revert("Missing config");
    }
  }
}
