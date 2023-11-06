// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPyth, INSDomainPrice, PeriodScaler } from "@rns-contracts/RNSDomainPrice.sol";
import { BaseDeploy, Network } from "foundry-deployment-kit/BaseDeploy.s.sol";

abstract contract RNSDeploy is BaseDeploy {
  struct Config {
    IPyth pyth;
    address admin;
    address pauser;
    address overrider;
    address controller;
    uint8 minWord;
    uint8 maxWord;
    address operator;
    address[] controllerOperators;
    address[] auctionOperators;
    address[] domainPriceOperators;
    uint256 taxRatio;
    uint64 gracePeriod;
    string baseTokenURI;
    uint256 bidGapRatio;
    address protectedSettler;
    address payable treasury;
    uint256 maxAcceptableAge;
    bytes32 pythIdForRONUSD;
    uint256 maxCommitmentAge;
    uint256 minCommitmentAge;
    uint256 minRegistrationDuration;
    PeriodScaler domainPriceScaleRule;
    INSDomainPrice.RenewalFee[] renewalFees;
  }

  function _buildMigrationConfig() internal view virtual returns (Config memory config) {
    config.auctionOperators = new address[](1);
    config.controllerOperators = new address[](1);
    config.domainPriceOperators = new address[](1);

    if (_network == Network.RoninTestnet) {
      config.minWord = 2;
      config.maxWord = 3;
      config.minCommitmentAge = 10 seconds;
      config.maxCommitmentAge = 1 days;
      config.gracePeriod = 90 days;

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

      config.baseTokenURI = "https://metadata-rns.skymavis.one/saigon/";
      config.admin = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.pauser = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;

      config.operator = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.auctionOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.controllerOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.domainPriceOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;

      config.controller = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.pyth = IPyth(0xA2aa501b19aff244D90cc15a4Cf739D2725B5729);
      config.protectedSettler = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      config.treasury = payable(0x968D0Cd7343f711216817E617d3f92a23dC91c07);
      config.pythIdForRONUSD = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;
    } else if (_network == Network.RoninMainnet) {
      config.baseTokenURI = "https://metadata-rns.roninchain.com/ronin/";
      config.pyth = IPyth(0x2880aB155794e7179c9eE2e38200202908C17B43);
      config.pythIdForRONUSD = 0x97cfe19da9153ef7d647b011c5e355142280ddb16004378573e6494e499879f3;
    } else {
      revert("Missing config");
    }
  }

  function _buildMigrationRawConfig() internal view override returns (bytes memory rawConfig) {
    Config memory config = _buildMigrationConfig();
    rawConfig = abi.encode(config);
  }

  function getConfig() public view returns (Config memory config) {
    bytes memory rawConfig = _config.getMigrationRawConfig();
    config = abi.decode(rawConfig, (Config));
  }
}
