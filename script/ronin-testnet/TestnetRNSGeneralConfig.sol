// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract, Network, BaseRNSGeneralConfig } from "script/BaseRNSGeneralConfig.sol";

contract TestnetRNSGeneralConfig is BaseRNSGeneralConfig {
  constructor(string memory artifactPath, string memory deploymentPath)
    BaseRNSGeneralConfig(artifactPath, deploymentPath)
  { }

  function _setUpContracts() internal virtual override {
    super._setUpContracts();

    setContractAbsolutePathMap(Contract.PublicResolver.key(), "resolvers/");
    setAddress(Network.RoninTestnet.key(), Contract.ProxyAdmin.key(), 0x505d91E8fd2091794b45b27f86C045529fa92CD7);
  }
}
