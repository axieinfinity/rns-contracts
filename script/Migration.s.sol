// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseMigration } from "@fdk/BaseMigration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { GeneralConfig } from "./GeneralConfig.sol";
import "./interfaces/ISharedArgument.sol";

abstract contract Migration is BaseMigration {
  ISharedArgument public constant config = ISharedArgument(address(CONFIG));

  function _configByteCode() internal virtual override returns (bytes memory) {
    return abi.encodePacked(type(GeneralConfig).creationCode);
  }

  function _sharedArguments() internal view virtual override returns (bytes memory rawArgs) {
    ISharedArgument.SharedParameter memory param;

    if (network() == DefaultNetwork.RoninTestnet.key() || network() == DefaultNetwork.LocalHost.key()) {
      address defaultAdmin = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
      address defaultPauser = defaultAdmin;
      address defaultOperator = defaultAdmin;
      address defaultController = defaultAdmin;

      // NameChecker
      param.nameChecker.minWord = 2;
      param.nameChecker.maxWord = 3;
      param.nameChecker.admin = defaultAdmin;

      // OwnedMulticaller
      param.ownedMulticaller.admin = defaultAdmin;

      // RNSOperation
      param.rnsOperation.admin = defaultAdmin;

      // PublicResolver
      param.publicResolver.admin = defaultAdmin;

      // RNSAuction
      param.rnsAuction.admin = defaultAdmin;
      param.rnsAuction.bidGapRatio = 1000; // 10%
      param.rnsAuction.treasury = payable(defaultAdmin);
      param.rnsAuction.auctionOperators = _toSingletonArray(defaultOperator);

      // RONRegistrarController
      param.ronRegistrarController.admin = defaultAdmin;
      param.ronRegistrarController.pauser = defaultPauser;
      param.ronRegistrarController.operator = defaultOperator;
      param.ronRegistrarController.treasury = payable(defaultAdmin);
      param.ronRegistrarController.maxAcceptableAge = 1 days;
      param.ronRegistrarController.minRegistrationDuration = 1 days;
      param.ronRegistrarController.minCommitmentAge = 10 seconds;

      // RNSDomainPrice
      param.rnsDomainPrice.admin = defaultAdmin;
      param.rnsDomainPrice.domainPriceOperators = _toSingletonArray(defaultOperator);
      param.rnsDomainPrice.renewalFees = new INSDomainPrice.RenewalFee[](3);
      param.rnsDomainPrice.renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
      param.rnsDomainPrice.renewalFees[1] = INSDomainPrice.RenewalFee(4, uint256(100e18) / 365 days);
      param.rnsDomainPrice.renewalFees[2] = INSDomainPrice.RenewalFee(3, uint256(300e18) / 365 days);
      param.rnsDomainPrice.taxRatio = 1500; // 15%
      param.rnsDomainPrice.maxAcceptableAge = 24 hours;
      param.rnsDomainPrice.pyth = IPyth(0xA2aa501b19aff244D90cc15a4Cf739D2725B5729);
      param.rnsDomainPrice.domainPriceScaleRule = PeriodScaler({ ratio: 500, period: 30 days * 3 });
      param.rnsDomainPrice.pythIdForRONUSD = 0x4cb9d530b042004b042e165ee0904b12fe534d40dac5fe1c71dfcdb522e6e3c2;

      // RNSUnified
      param.rnsUnified.admin = defaultAdmin;
      param.rnsUnified.pauser = defaultPauser;
      param.rnsUnified.controller = defaultController;
      param.rnsUnified.protectedSettler = defaultAdmin;
      param.rnsUnified.gracePeriod = 90 days;
      param.rnsUnified.baseTokenURI = "https://metadata-rns.skymavis.one/saigon/";

      // RNSCommission
      param.rnsCommission.admin = defaultAdmin;
      param.rnsCommission.commissionSetters = new address[](1);
      param.rnsCommission.commissionSetters[0] = defaultAdmin;

      param.rnsCommission.allowedSenders = new address[](2);

      param.rnsCommission.treasuryCommission = new INSCommission.Commission[](2);
      param.rnsCommission.treasuryCommission[0].recipient = payable(defaultAdmin);
      param.rnsCommission.treasuryCommission[0].ratio = 70_00;
      param.rnsCommission.treasuryCommission[0].name = "Sky Mavis";

      param.rnsCommission.treasuryCommission[1].recipient = payable(defaultAdmin);
      param.rnsCommission.treasuryCommission[1].ratio = 30_00;
      param.rnsCommission.treasuryCommission[1].name = "Ronin";
    } else if (network() == DefaultNetwork.RoninMainnet.key()) {
      address duke = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
      address andy = 0xEd4A9F48a62Fb6FdcfB45Bb00C9f61D1A436E58C;
      address harry = 0x0A9E57c71af2b1194C5f573F4bB1e45696c49213;

      address temporaryDeployer = duke;
      address temporaryAdmin = duke;
      address temporaryPauser = duke;
      address temporaryOperator = duke;
      address temporaryController = andy;

      address operator = harry;
      address payable treasury = payable(andy);

      // NameChecker
      param.nameChecker.minWord = 2;
      param.nameChecker.maxWord = 3;
      param.nameChecker.admin = temporaryAdmin;

      // OwnedMulticaller
      param.ownedMulticaller.admin = temporaryDeployer;

      // RNSOperation
      param.rnsOperation.admin = temporaryDeployer;

      // PublicResolver
      param.publicResolver.admin = temporaryAdmin;

      // RNSAuction
      param.rnsAuction.admin = temporaryAdmin;
      param.rnsAuction.bidGapRatio = 1000; // 10%
      param.rnsAuction.treasury = payable(temporaryAdmin);
      param.rnsAuction.auctionOperators = _toSingletonArray(temporaryOperator);

      // RONRegistrarController
      param.ronRegistrarController.admin = temporaryAdmin;
      param.ronRegistrarController.pauser = temporaryPauser;
      param.ronRegistrarController.operator = temporaryOperator;
      param.ronRegistrarController.treasury = treasury;
      param.ronRegistrarController.maxAcceptableAge = 1 days;
      param.ronRegistrarController.minRegistrationDuration = 1 days;
      param.ronRegistrarController.minCommitmentAge = 10 seconds;

      // RNSDomainPrice
      param.rnsDomainPrice.admin = temporaryAdmin;
      param.rnsDomainPrice.overrider = duke;
      param.rnsDomainPrice.domainPriceOperators = _toSingletonArray(operator);
      param.rnsDomainPrice.renewalFees = new INSDomainPrice.RenewalFee[](4);
      param.rnsDomainPrice.renewalFees[0] = INSDomainPrice.RenewalFee(5, uint256(5e18) / 365 days);
      param.rnsDomainPrice.renewalFees[1] = INSDomainPrice.RenewalFee(4, uint256(100e18) / 365 days);
      param.rnsDomainPrice.renewalFees[2] = INSDomainPrice.RenewalFee(3, uint256(300e18) / 365 days);
      param.rnsDomainPrice.renewalFees[3] = INSDomainPrice.RenewalFee(2, uint256(300e18) / 365 days);
      param.rnsDomainPrice.taxRatio = 1500; // 15%
      param.rnsDomainPrice.maxAcceptableAge = 24 hours;
      param.rnsDomainPrice.pyth = IPyth(0x2880aB155794e7179c9eE2e38200202908C17B43);
      param.rnsDomainPrice.domainPriceScaleRule = PeriodScaler({ ratio: 500, period: 30 days * 3 });
      param.rnsDomainPrice.pythIdForRONUSD = 0x97cfe19da9153ef7d647b011c5e355142280ddb16004378573e6494e499879f3;

      // RNSUnified
      param.rnsUnified.admin = temporaryAdmin;
      param.rnsUnified.pauser = temporaryPauser;
      param.rnsUnified.controller = temporaryController;
      param.rnsUnified.protectedSettler = temporaryAdmin;
      param.rnsUnified.gracePeriod = 90 days;
      param.rnsUnified.baseTokenURI = "https://metadata-rns.roninchain.com/ronin/";

      // RNSCommission
      param.rnsCommission.admin = 0x9D05D1F5b0424F8fDE534BC196FFB6Dd211D902a;
      param.rnsCommission.commissionSetters = new address[](1);
      param.rnsCommission.commissionSetters[0] = 0x9D05D1F5b0424F8fDE534BC196FFB6Dd211D902a;

      param.rnsCommission.allowedSenders = new address[](2);

      param.rnsCommission.treasuryCommission = new INSCommission.Commission[](2);
      param.rnsCommission.treasuryCommission[0].recipient = payable(0xFf43f5Ef28EcB7c1f219751fc793deB40ef07A53);
      param.rnsCommission.treasuryCommission[0].ratio = 70_00;
      param.rnsCommission.treasuryCommission[0].name = "Sky Mavis";

      param.rnsCommission.treasuryCommission[1].recipient = payable(0x22cEfc91E9b7c0f3890eBf9527EA89053490694e);
      param.rnsCommission.treasuryCommission[1].ratio = 30_00;
      param.rnsCommission.treasuryCommission[1].name = "Ronin";
    } else {
      revert("Missing param");
    }

    rawArgs = abi.encode(param);
  }

  function _toSingletonArray(address addr) internal pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = addr;
  }
}
