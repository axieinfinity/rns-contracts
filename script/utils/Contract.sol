// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibString } from "lib/solady/src/utils/LibString.sol";
import { TContract } from "foundry-deployment-kit/types/Types.sol";

enum Contract {
  RNSUnified,
  RNSAuction,
  NameChecker,
  RNSOperation,
  RNSDomainPrice,
  PublicResolver,
  OwnedMulticaller,
  RNSReverseRegistrar,
  RONRegistrarController
}

using { key, name } for Contract global;

function key(Contract contractEnum) pure returns (TContract) {
  return TContract.wrap(LibString.packOne(name(contractEnum)));
}

function name(Contract contractEnum) pure returns (string memory) {
  if (contractEnum == Contract.RNSUnified) return "RNSUnified";
  if (contractEnum == Contract.RNSAuction) return "RNSAuction";
  if (contractEnum == Contract.NameChecker) return "NameChecker";
  if (contractEnum == Contract.RNSOperation) return "RNSOperation";
  if (contractEnum == Contract.RNSDomainPrice) return "RNSDomainPrice";
  if (contractEnum == Contract.PublicResolver) return "PublicResolver";
  if (contractEnum == Contract.OwnedMulticaller) return "OwnedMulticaller";
  if (contractEnum == Contract.RNSReverseRegistrar) return "RNSReverseRegistrar";
  if (contractEnum == Contract.RONRegistrarController) return "RONRegistrarController";
  revert("Contract: Unknown contract");
}