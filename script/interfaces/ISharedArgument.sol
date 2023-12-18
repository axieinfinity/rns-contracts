// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IGeneralConfig } from "foundry-deployment-kit/interfaces/IGeneralConfig.sol";
import { IPyth, INSDomainPrice, PeriodScaler } from "@rns-contracts/RNSDomainPrice.sol";

interface ISharedArgument is IGeneralConfig {
  struct SharedParameter {
    IPyth pyth;
    address admin;
    address pauser;
    address overrider;
    address controller;
    uint8 minWord;
    uint8 maxWord;
    address rnsOperationOwner;
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

  function sharedArguments() external view returns (SharedParameter memory param);
}
