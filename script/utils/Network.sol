// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TNetwork } from "foundry-deployment-kit/types/Types.sol";

enum Network {
  Local,
  RoninTestnet,
  RoninMainnet
}

using { key, chainId } for Network global;

function chainId(Network network) pure returns (uint256) {
  if (network == Network.Local) return 31337;
  if (network == Network.RoninMainnet) return 2020;
  if (network == Network.RoninTestnet) return 2021;
  return 0;
}

function key(Network network) pure returns (TNetwork) {
  return TNetwork.wrap(uint8(network));
}
