// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TContract } from "foundry-deployment-kit/types/Types.sol";

enum Contract {
  RNSUnified,
  RNSAuction,
  ProxyAdmin,
  NameChecker,
  RNSDomainPrice,
  PublicResolver,
  RNSReverseRegistrar,
  RONRegistrarController
}

using { key, name } for Contract global;

function key(Contract contractEnum) pure returns (TContract) {
  return TContract.wrap(uint8(contractEnum));
}

function name(Contract contractEnum) pure returns (string memory) {
  if (contractEnum == Contract.RNSUnified) return "RNSUnified";
  if (contractEnum == Contract.ProxyAdmin) return "ProxyAdmin";
  if (contractEnum == Contract.RNSAuction) return "RNSAuction";
  if (contractEnum == Contract.NameChecker) return "NameChecker";
  if (contractEnum == Contract.PublicResolver) return "PublicResolver";
  if (contractEnum == Contract.RNSDomainPrice) return "RNSDomainPrice";
  if (contractEnum == Contract.RNSReverseRegistrar) return "RNSReverseRegistrar";
  if (contractEnum == Contract.RONRegistrarController) return "RONRegistrarController";
  return "";
}
