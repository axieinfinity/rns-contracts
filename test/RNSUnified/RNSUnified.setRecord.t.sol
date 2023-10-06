// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_SetRecord_Test is RNSUnifiedTest {
  using LibModifyingField for ModifyingField;

  INSUnified.MutableRecord internal _emptyMutRecord;

  function testFuzz_WhenMinted_AsProtectedSettler_CanSetProtectedField_canSetRecord(
    MintParam calldata mintParam,
    INSUnified.MutableRecord calldata mutRecord
  ) external mintAs(_controller) setRecordAs(_protectedSettler) {
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, ModifyingField.Protected.indicator());
    assertTrue(allowed, _errorIndentifier[error]);

    _setRecord(id, ModifyingField.Protected.indicator(), mutRecord, _noError);
  }

  function testFuzz_WhenMinted_AsController_CanSetMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam,
    INSUnified.MutableRecord calldata mutRecord
  ) external mintAs(_controller) setRecordAs(_controller) {
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));
    vm.assume(!indicator.hasAny(ModifyingField.Protected.indicator()));
    if (indicator.hasAny(ModifyingField.Owner.indicator())) {
      _assumeValidAccount(mutRecord.owner);
    }
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_controller, id, indicator);
    assertTrue(allowed, _errorIndentifier[error]);

    _setRecord(id, indicator, mutRecord, _noError);
  }

  function testFuzz_WhenMinted_AsController_CannotSetProtectedField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) setRecordAs(_controller) {
    vm.assume(indicator.hasAny(ModifyingField.Protected.indicator()));
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_controller, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }

  function testFuzz_WhenMinted_AsProtectedSettler_CannotSetImmutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) setRecordAs(_protectedSettler) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }

  function testFuzz_WhenMinted_AsProtectedSettler_CannotSetOtherMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external mintAs(_controller) setRecordAs(_protectedSettler) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(USER_FIELDS_INDICATOR));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetProtectedField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external setRecordAs(_protectedSettler) {
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));
    vm.assume(indicator.hasAny(ModifyingField.Protected.indicator()));
    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.Unexists.selector, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetImmutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external setRecordAs(_protectedSettler) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.CannotSetImmutableField.selector, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }

  function testFuzz_WhenNotMinted_AsProtectedSettler_CannotSetOtherMutableField_canSetRecord(
    ModifyingIndicator indicator,
    MintParam calldata mintParam
  ) external setRecordAs(_protectedSettler) {
    vm.assume(indicator != ModifyingIndicator.wrap(0x00));
    vm.assume(indicator.hasAny(USER_FIELDS_INDICATOR));
    vm.assume(!indicator.hasAny(IMMUTABLE_FIELDS_INDICATOR));

    uint256 id = _toId(_ronId, mintParam.name);
    (bool allowed, bytes4 error) = _rns.canSetRecord(_protectedSettler, id, indicator);
    assertFalse(allowed, _errorIndentifier[error]);
    assertEq(error, INSUnified.Unexists.selector, _errorIndentifier[error]);

    _setRecord(id, indicator, _emptyMutRecord, Error(true, abi.encodeWithSelector(error)));
  }
}
