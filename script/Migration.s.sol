// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseMigration } from "foundry-deployment-kit/BaseMigration.s.sol";
import { DefaultNetwork } from "foundry-deployment-kit/utils/DefaultNetwork.sol";
import { GeneralConfig } from "./GeneralConfig.sol";
import "./interfaces/ISharedArgument.sol";

abstract contract Migration is BaseMigration {
  ISharedArgument public constant config = ISharedArgument(address(CONFIG));

  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(GeneralConfig).creationCode);
  }

  function _sharedArguments() internal view virtual override returns (bytes memory rawArgs) {
    ISharedArgument.SharedParameter memory param;

    param.auctionOperators = new address[](1);
    param.controllerOperators = new address[](1);
    param.domainPriceOperators = new address[](1);

    if (network() == DefaultNetwork.RoninTestnet.key()) {
      param.minWord = 2;
      param.maxWord = 3;
      param.minCommitmentAge = 10 seconds;
      param.maxCommitmentAge = 1 days;
      param.gracePeriod = 90 days;

      {
        param.renewalFees = new INSDomainPrice.RenewalFee[](3);
        param.renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
        param.renewalFees[1] = INSDomainPrice.RenewalFee(4, uint256(100e18) / 365 days);
        param.renewalFees[2] = INSDomainPrice.RenewalFee(3, uint256(300e18) / 365 days);
      }
      param.bidGapRatio = 1000; // 10%
      param.taxRatio = 1500; // 15%
      param.maxAcceptableAge = 24 hours;
      param.domainPriceScaleRule = PeriodScaler({ ratio: 500, period: 30 days * 3 });

      param.baseTokenURI = "https://metadata-rns.skymavis.one/saigon/";
      param.admin = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.pauser = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;

      param.operator = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.auctionOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.controllerOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.domainPriceOperators[0] = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;

      param.controller = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.pyth = IPyth(0xA2aa501b19aff244D90cc15a4Cf739D2725B5729);
      param.protectedSettler = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      param.treasury = payable(0x968D0Cd7343f711216817E617d3f92a23dC91c07);
      param.pythIdForRONUSD = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;
    } else if (network() == DefaultNetwork.RoninMainnet.key()) {
      address temporaryDeployer = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;

      param.minWord = 2;
      param.maxWord = 3;

      param.minCommitmentAge = 10 seconds;
      param.maxCommitmentAge = 1 days;
      param.gracePeriod = 90 days;

      {
        param.renewalFees = new INSDomainPrice.RenewalFee[](4);
        param.renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
        param.renewalFees[1] = INSDomainPrice.RenewalFee(4, uint256(100e18) / 365 days);
        param.renewalFees[2] = INSDomainPrice.RenewalFee(3, uint256(300e18) / 365 days);
        param.renewalFees[3] = INSDomainPrice.RenewalFee(2, uint256(300e18) / 365 days);
      }
      param.bidGapRatio = 1000; // 10%
      param.taxRatio = 1500; // 15%
      param.maxAcceptableAge = 24 hours;
      param.domainPriceScaleRule = PeriodScaler({ ratio: 500, period: 30 days * 3 });

      param.baseTokenURI = "https://metadata-rns.roninchain.com/ronin/";
      param.admin = temporaryDeployer;
      param.pauser = temporaryDeployer;
      param.protectedSettler = temporaryDeployer;

      param.auctionOperators[0] = temporaryDeployer;
      param.controllerOperators[0] = temporaryDeployer;
      param.domainPriceOperators[0] = 0x0A9E57c71af2b1194C5f573F4bB1e45696c49213; // Harry

      param.controller = 0xEd4A9F48a62Fb6FdcfB45Bb00C9f61D1A436E58C;
      param.treasury = payable(0xEd4A9F48a62Fb6FdcfB45Bb00C9f61D1A436E58C); // Andy
      param.pyth = IPyth(0x2880aB155794e7179c9eE2e38200202908C17B43); // Harry
      param.pythIdForRONUSD = 0x97cfe19da9153ef7d647b011c5e355142280ddb16004378573e6494e499879f3; // Harry
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }
}
