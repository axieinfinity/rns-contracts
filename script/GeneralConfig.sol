// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseGeneralConfig } from "@fdk/BaseGeneralConfig.sol";
import { Contract } from "./utils/Contract.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";

contract GeneralConfig is BaseGeneralConfig {
  constructor() BaseGeneralConfig("", "deployments/") { }

  function _setUpContracts() internal virtual override {
    _mapContractName(Contract.RNSUnified);
    _mapContractName(Contract.RNSAuction);
    _mapContractName(Contract.NameChecker);
    _mapContractName(Contract.RNSOperation);
    _mapContractName(Contract.RNSDomainPrice);
    _mapContractName(Contract.PublicResolver);
    _mapContractName(Contract.OwnedMulticaller);
    _mapContractName(Contract.RNSReverseRegistrar);
    _mapContractName(Contract.RONRegistrarController);
    _mapContractName(Contract.RNSCommission);
    _mapContractName(Contract.ERC721BatchTransfer);

    // Verify: https://app.roninchain.com/address/0x2368dfED532842dB89b470fdE9Fd584d48D4F644
    setAddress(
      DefaultNetwork.RoninMainnet.key(), Contract.ERC721BatchTransfer.key(), 0x2368dfED532842dB89b470fdE9Fd584d48D4F644
    );
    // Verify: https://saigon-app.roninchain.com/address/0x2E889348bD37f192063Bfec8Ff39bD3635949e20
    setAddress(
      DefaultNetwork.RoninTestnet.key(), Contract.ERC721BatchTransfer.key(), 0x2E889348bD37f192063Bfec8Ff39bD3635949e20
    );
  }

  function _mapContractName(Contract contractEnum) internal {
    _contractNameMap[contractEnum.key()] = contractEnum.name();
  }
}
