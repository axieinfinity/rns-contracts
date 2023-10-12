//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

type ModifyingIndicator is uint256;

using { hasAny } for ModifyingIndicator global;
using { or as | } for ModifyingIndicator global;
using { and as & } for ModifyingIndicator global;
using { eq as == } for ModifyingIndicator global;
using { not as ~ } for ModifyingIndicator global;
using { neq as != } for ModifyingIndicator global;

/// @dev Indicator for modifying immutable fields: Depth, ParentId, Label. See struct {INSUnified.ImmutableRecord}.
ModifyingIndicator constant IMMUTABLE_FIELDS_INDICATOR = ModifyingIndicator.wrap(0x7);

/// @dev Indicator for modifying user fields: Resolver, Owner. See struct {INSUnified.MutableRecord}.
ModifyingIndicator constant USER_FIELDS_INDICATOR = ModifyingIndicator.wrap(0x18);

/// @dev Indicator when modifying all of the fields in {ModifyingField}.
ModifyingIndicator constant ALL_FIELDS_INDICATOR = ModifyingIndicator.wrap(type(uint256).max);

function eq(ModifyingIndicator self, ModifyingIndicator other) pure returns (bool) {
  return ModifyingIndicator.unwrap(self) == ModifyingIndicator.unwrap(other);
}

function neq(ModifyingIndicator self, ModifyingIndicator other) pure returns (bool) {
  return !eq(self, other);
}

function not(ModifyingIndicator self) pure returns (ModifyingIndicator) {
  return ModifyingIndicator.wrap(~ModifyingIndicator.unwrap(self));
}

function or(ModifyingIndicator self, ModifyingIndicator other) pure returns (ModifyingIndicator) {
  return ModifyingIndicator.wrap(ModifyingIndicator.unwrap(self) | ModifyingIndicator.unwrap(other));
}

function and(ModifyingIndicator self, ModifyingIndicator other) pure returns (ModifyingIndicator) {
  return ModifyingIndicator.wrap(ModifyingIndicator.unwrap(self) & ModifyingIndicator.unwrap(other));
}

function hasAny(ModifyingIndicator self, ModifyingIndicator other) pure returns (bool) {
  return self & other != ModifyingIndicator.wrap(0);
}
