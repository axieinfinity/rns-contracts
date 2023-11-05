// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPyth, INSDomainPrice, PeriodScaler } from "@rns-contracts/RNSDomainPrice.sol";
import { BaseMigration } from "foundry-deployment-kit/BaseMigration.s.sol";
import { BaseRNSGeneralConfig } from "./BaseRNSGeneralConfig.sol";
import { Network } from "./utils/Network.sol";
import { Contract } from "./utils/Contract.sol";

abstract contract BaseRNSMigration is BaseMigration {
  struct Config {
    IPyth pyth;
    address admin;
    address pauser;
    address overrider;
    address controller;
    uint8 minWord;
    uint8 maxWord;
    address operator;
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

  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(BaseRNSGeneralConfig).creationCode, abi.encode("", "deployments/"));
  }

  function _buildMigrationConfig() internal view virtual returns (Config memory config) {
    if (network() == Network.Local.key() || network() == Network.RoninTestnet.key()) {
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

      config.admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
      config.pauser = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
      config.operator = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
      config.controller = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
      config.pyth = IPyth(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      config.protectedSettler = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
      config.treasury = payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      config.pythIdForRONUSD = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;
    } else {
      revert("Missing config");
    }
  }

  function _buildMigrationRawConfig() internal view override returns (bytes memory rawConfig) {
    Config memory config = _buildMigrationConfig();
    rawConfig = abi.encode(config);
  }

  function getConfig() public view returns (Config memory config) {
    bytes memory rawConfig = CONFIG.getMigrationRawConfig();
    config = abi.decode(rawConfig, (Config));
  }
}
