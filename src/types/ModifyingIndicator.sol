//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

type ModifyingIndicator is uint256;

using {hasAny} for ModifyingIndicator global;
using {or as |} for ModifyingIndicator global;

/// @dev Indicator for modifying immutable fields: Depth, ParentId, Label. See struct {INSUnified.ImmutableRecord}.
ModifyingIndicator constant IMMUTABLE_FIELDS_INDICATOR = ModifyingIndicator.wrap(0x7);

/// @dev Indicator when modifying all of the fields in {ModifyingField}.
ModifyingIndicator constant ALL_FIELDS_INDICATOR = ModifyingIndicator.wrap(type(uint256).max);

function or(ModifyingIndicator self, ModifyingIndicator other) pure returns (ModifyingIndicator) {
  return ModifyingIndicator.wrap(ModifyingIndicator.unwrap(self) | ModifyingIndicator.unwrap(other));
}

function hasAny(ModifyingIndicator self, ModifyingIndicator other) pure returns (bool) {
  return ModifyingIndicator.unwrap(or(self, other)) != 0;
}
