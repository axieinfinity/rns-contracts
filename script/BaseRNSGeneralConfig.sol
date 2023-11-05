// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { StdStyle, console2, BaseGeneralConfig } from "foundry-deployment-kit/BaseGeneralConfig.sol";
import { Network } from "./utils/Network.sol";
import { Contract } from "./utils/Contract.sol";

contract BaseRNSGeneralConfig is BaseGeneralConfig {
  constructor(string memory artifactPath, string memory deploymentPath) BaseGeneralConfig(artifactPath, deploymentPath) { }

  function _setUpNetworks() internal virtual override {
    setNetworkInfo(
      Network.RoninTestnet.chainId(), Network.RoninTestnet.key(), "ronin-testnet", "ronin-testnet/", "TESTNET_PK"
    );
    setNetworkInfo(
      Network.RoninMainnet.chainId(), Network.RoninMainnet.key(), "ronin-mainnet", "ronin-mainnet/", "MAINNET_PK"
    );
  }

  function _setUpContracts() internal virtual override {
    _mapContractName(Contract.RNSUnified);
    _mapContractName(Contract.ProxyAdmin);
    _mapContractName(Contract.RNSAuction);
    _mapContractName(Contract.NameChecker);
    _mapContractName(Contract.PublicResolver);
    _mapContractName(Contract.RNSDomainPrice);
    _mapContractName(Contract.RNSReverseRegistrar);
    _mapContractName(Contract.RONRegistrarController);
  }

  function _mapContractName(Contract contractEnum) internal {
    _contractNameMap[contractEnum.key()] = contractEnum.name();
  }

  function _setUpDefaultSender() internal virtual override {
    // by default we will read private key from .env
    _envSender = vm.rememberKey(vm.envUint(getPrivateKeyEnvLabel(getCurrentNetwork())));
    console2.log(StdStyle.blue(".ENV Account:"), _envSender);
    vm.label(_envSender, "env:sender");
  }
}
