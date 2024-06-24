// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGeneralConfig } from "foundry-deployment-kit/interfaces/IGeneralConfig.sol";
import { IPyth, INSDomainPrice, PeriodScaler } from "@rns-contracts/RNSDomainPrice.sol";
import { NameChecker } from "@rns-contracts/NameChecker.sol";
import { PublicResolver } from "@rns-contracts/resolvers/PublicResolver.sol";
import { RNSAuction } from "@rns-contracts/RNSAuction.sol";
import { RNSReverseRegistrar } from "@rns-contracts/RNSReverseRegistrar.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { RNSDomainPrice } from "@rns-contracts/RNSDomainPrice.sol";
import { RNSOperation } from "@rns-contracts/utils/RNSOperation.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";
import { RNSCommission, INSCommission } from "@rns-contracts/RNSCommission.sol";

interface ISharedArgument is IGeneralConfig {
  struct NameCheckerParam {
    address admin;
    uint8 minWord;
    uint8 maxWord;
  }

  struct OwnedMulticallerParam {
    address admin;
  }

  struct PublicResolverParam {
    address admin;
    RNSUnified rnsUnified;
    RNSReverseRegistrar rnsReverseRegistrar;
  }

  struct RNSAuctionParam {
    address admin;
    address[] auctionOperators;
    RNSUnified rnsUnified;
    address payable treasury;
    uint256 bidGapRatio;
  }

  struct RNSDomainPriceParam {
    address admin;
    address overrider;
    address[] domainPriceOperators;
    INSDomainPrice.RenewalFee[] renewalFees;
    uint256 taxRatio;
    PeriodScaler domainPriceScaleRule;
    IPyth pyth;
    RNSAuction rnsAuction;
    uint256 maxAcceptableAge;
    bytes32 pythIdForRONUSD;
  }

  struct RNSOperationParam {
    address admin;
    address rnsUnified;
    address publicResolver;
    address rnsAuction;
    address rnsDomainPrice;
  }

  struct RNSReverseRegistrarParam {
    address admin;
    RNSUnified rnsUnified;
  }

  struct RNSUnifiedParam {
    address admin;
    address pauser;
    address controller;
    address protectedSettler;
    uint64 gracePeriod;
    string baseTokenURI;
  }

  struct RONRegistrarControllerParam {
    address admin;
    address pauser;
    address operator;
    address payable treasury;
    uint256 maxAcceptableAge;
    uint256 minCommitmentAge;
    uint256 minRegistrationDuration;
    RNSUnified rnsUnified;
    NameChecker nameChecker;
    RNSDomainPrice rnsDomainPrice;
    RNSReverseRegistrar rnsReverseRegistrar;
  }

  struct RNSCommissionParam {
    address admin;
    address[] commissionSetters;
    INSCommission.Commission[] treasuryCommission;
    address[] allowedSenders;
  }

  struct SharedParameter {
    NameCheckerParam nameChecker;
    OwnedMulticallerParam ownedMulticaller;
    PublicResolverParam publicResolver;
    RNSAuctionParam rnsAuction;
    RNSDomainPriceParam rnsDomainPrice;
    RNSOperationParam rnsOperation;
    RNSReverseRegistrarParam rnsReverseRegistrar;
    RNSUnifiedParam rnsUnified;
    RONRegistrarControllerParam ronRegistrarController;
    RNSCommissionParam rnsCommission;
  }

  function sharedArguments() external view returns (SharedParameter memory param);
}
