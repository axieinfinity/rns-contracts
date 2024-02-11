// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISharedArgument, DefaultNetwork, Migration } from "script/Migration.s.sol";

abstract contract Config__20231024 is Migration {
  function _sharedArguments() internal view virtual override returns (bytes memory rawArgs) {
    rawArgs = super._sharedArguments();

    ISharedArgument.SharedParameter memory param = abi.decode(rawArgs, (ISharedArgument.SharedParameter));

    if (network() == DefaultNetwork.RoninTestnet.key()) {
      param.rnsDomainPrice.overrider = param.rnsDomainPrice.domainPriceOperators[0];
    } else if (network() == DefaultNetwork.RoninMainnet.key()) {
      revert("Missing param");
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }
}
