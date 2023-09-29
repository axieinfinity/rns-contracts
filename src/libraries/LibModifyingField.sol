//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ModifyingIndicator } from "../types/ModifyingIndicator.sol";

enum ModifyingField {
  Depth,
  ParentId,
  Label,
  Resolver,
  Ttl,
  Owner,
  Expiry,
  Protected
}

library LibModifyingField {
  function indicator(ModifyingField opt) internal pure returns (ModifyingIndicator) {
    return ModifyingIndicator.wrap(1 << uint8(opt));
  }
}
