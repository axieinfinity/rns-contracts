// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_SetRecord_Test is RNSUnifiedTest {
  using LibModifyingField for ModifyingField;

  function testFuzz_WhenMinted_AsProtectedSettler_CanSetProtectedField_canSetRecord(
    MintParam calldata mintParam,
    INSUnified.MutableRecord calldata mutRecord
  ) external mintAs(_controller) {
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, ModifyingField.Protected.indicator());
    assertTrue(allowed, _errorIndentifier[error]);

    INSUnified.MutableRecord memory mutRecordBefore = _rns.getRecord(id).mut;

    vm.prank(_protectedSettler);
    _rns.setRecord(id, ModifyingField.Protected.indicator(), mutRecord);

    INSUnified.MutableRecord memory mutRecordAfter = _rns.getRecord(id).mut;

    assertEq(mutRecordAfter.protected, mutRecord.protected);
    // remains unchanged
    assertEq(mutRecordBefore.owner, mutRecordAfter.owner);
    assertEq(mutRecordBefore.expiry, mutRecordAfter.expiry);
    assertEq(mutRecordBefore.resolver, mutRecordAfter.resolver);
  }

  function testFuzz_WhenMinted_AsController_CanSetMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam,
    INSUnified.MutableRecord calldata mutRecord
  ) external mintAs(_controller) {
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));
    vm.assume(!indicator.hasAny(ModifyingField.Protected.indicator()));
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_controller, id, indicator);
    assertTrue(allowed, _errorIndentifier[error]);

    INSUnified.MutableRecord memory mutRecordBefore = _rns.getRecord(id).mut;

    vm.prank(_controller);
    _rns.setRecord(id, indicator, mutRecord);

    INSUnified.MutableRecord memory mutRecordAfter = _rns.getRecord(id).mut;

    if (indicator.hasAny(ModifyingField.Owner.indicator())) {
      assertEq(mutRecordAfter.owner, mutRecord.owner);
    } else {
      assertEq(mutRecordAfter.owner, mutRecordBefore.owner);
    }
    if (indicator.hasAny(ModifyingField.Expiry.indicator())) {
      assertEq(mutRecordAfter.expiry, mutRecord.expiry);
    } else {
      assertEq(mutRecordAfter.expiry, mutRecordBefore.expiry);
    }
    if (indicator.hasAny(ModifyingField.Resolver.indicator())) {
      assertEq(mutRecordAfter.resolver, mutRecord.resolver);
    } else {
      assertEq(mutRecordAfter.resolver, mutRecordBefore.resolver);
    }

    // remains unchanged
    assertEq(mutRecordAfter.protected, mutRecordBefore.protected);
  }

  function testFuzz_WhenMinted_AsController_CannotSetProtectedField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) {
    vm.assume(indicator.hasAny(ModifyingField.Protected.indicator()));
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_controller, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
  }

  function testFuzz_WhenMinted_AsProtectedSettler_CannotSetImmutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
  }

  function testFuzz_WhenMinted_AsProtectedSettler_CannotSetOtherMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(USER_FIELDS_INDICATOR));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetProtectedField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external {
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));
    vm.assume(indicator.hasAny(ModifyingField.Protected.indicator()));
    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.Unexists.selector, _errorIndentifier[error]);
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetImmutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.CannotSetImmutableField.selector, _errorIndentifier[error]);
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetOtherMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(USER_FIELDS_INDICATOR));
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.Unexists.selector, _errorIndentifier[error]);
  }

  function testFuzz_AsController_canSetMutableRecord_canSetRecord(MintParam calldata mintParam)
    external
    mintAs(_controller)
  { }
}
