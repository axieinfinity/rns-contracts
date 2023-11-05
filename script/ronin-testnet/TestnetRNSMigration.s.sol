// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPyth, PeriodScaler, Contract, Network, INSDomainPrice, BaseRNSMigration } from "script/BaseRNSMigration.s.sol";
import { TestnetRNSGeneralConfig } from "./TestnetRNSGeneralConfig.sol";

abstract contract TestnetRNSMigration is BaseRNSMigration {
  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(TestnetRNSGeneralConfig).creationCode, abi.encode("src/", "deployments/"));
  }

  function _buildMigrationConfig() internal view virtual override returns (Config memory config) {
    config.minWord = 2;
    config.maxWord = 3;
    config.minCommitmentAge = 10 seconds;
    config.maxCommitmentAge = 1 days;
    config.gracePeriod = 90 days;
    config.baseTokenURI = "https://metadata-rns.skymavis.one/saigon/";
    {
      config.renewalFees = new INSDomainPrice.RenewalFee[](3);
      config.renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
      config.renewalFees[1] = INSDomainPrice.RenewalFee(4, uint256(100e18) / 365 days);
      config.renewalFees[2] = INSDomainPrice.RenewalFee(3, uint256(300e18) / 365 days);
    }
    config.bidGapRatio = 1000; // 10%
    config.taxRatio = 1500; // 15%
    config.maxAcceptableAge = 24 hours;
    config.domainPriceScaleRule = PeriodScaler({ ratio: 500, period: 30 days * 3 });

    if (network() == Network.RoninTestnet.key()) {
      config.admin = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.pauser = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.operator = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.controller = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.pyth = IPyth(0xA2aa501b19aff244D90cc15a4Cf739D2725B5729);
      config.protectedSettler = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.treasury = payable(0x968D0Cd7343f711216817E617d3f92a23dC91c07);
      config.pythIdForRONUSD = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;
    } else if (network() == Network.RoninMainnet.key()) {
      revert("Missing config");
    } else {
      revert("Missing config");
    }
  }
}
