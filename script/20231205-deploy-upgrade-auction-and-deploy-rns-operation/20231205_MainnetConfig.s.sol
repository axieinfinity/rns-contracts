// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, DefaultNetwork, Migration } from "script/Migration.s.sol";

abstract contract Config__Mainnet20231205 is Migration {
  function _sharedArguments() internal view virtual override returns (bytes memory rawArgs) {
    rawArgs = super._sharedArguments();
    ISharedArgument.SharedParameter memory param = abi.decode(rawArgs, (ISharedArgument.SharedParameter));

    if (network() == DefaultNetwork.RoninMainnet.key()) {
      param.rnsOperationOwner = 0x1FF1edE0242317b8C4229fC59E64DD93952019ef;
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }
}
