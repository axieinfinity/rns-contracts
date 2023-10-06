// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_Reclaim_Test is RNSUnifiedTest {
  using LibModifyingField for *;

  function test_WhenMintedAndTransferedToNewOwner_AsController_ReclaimOwnership_reclaim(
    address newOwner,
    MintParam calldata mintParam
  ) external mintAs(_controller) validAccount(newOwner) {
    vm.assume(newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    vm.prank(mintParam.owner);
    _rns.transferFrom(mintParam.owner, newOwner, id);

    assertEq(newOwner, _rns.ownerOf(id));
    assertEq(newOwner, _rns.getRecord(id).mut.owner);

    INSUnified.Record memory emittedRecord;
    emittedRecord.mut.owner = mintParam.owner;
    vm.expectEmit(address(_rns));
    emit RecordUpdated(id, ModifyingField.Owner.indicator(), emittedRecord);
    vm.prank(_controller);
    _rns.reclaim(id, mintParam.owner);

    assertEq(mintParam.owner, _rns.ownerOf(id));
    assertEq(mintParam.owner, _rns.getRecord(id).mut.owner);
  }

  function test_WhenMinted_AsParentOwner_ReclaimOwnership_reclaim(address newOwner, MintParam calldata mintParam)
    external
    mintAs(_controller)
    validAccount(newOwner)
  {
    vm.assume(newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    INSUnified.Record memory emittedRecord;
    emittedRecord.mut.owner = newOwner;
    vm.expectEmit(address(_rns));
    emit RecordUpdated(id, ModifyingField.Owner.indicator(), emittedRecord);
    vm.prank(_admin);
    _rns.reclaim(id, newOwner);

    assertEq(newOwner, _rns.ownerOf(id));
    assertEq(newOwner, _rns.getRecord(id).mut.owner);
  }

  function test_WhenMinted_AsApproved_ReclaimOwnership_reclaim(
    address approved,
    address newOwner,
    MintParam calldata mintParam
  ) external mintAs(_controller) validAccount(approved) validAccount(newOwner) {
    vm.assume(approved != mintParam.owner);
    vm.assume(newOwner != mintParam.owner);

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    vm.prank(mintParam.owner);
    _rns.approve(approved, id);

    INSUnified.Record memory emittedRecord;
    emittedRecord.mut.owner = newOwner;
    vm.expectEmit(address(_rns));
    emit RecordUpdated(id, ModifyingField.Owner.indicator(), emittedRecord);
    vm.prank(approved);
    _rns.reclaim(id, newOwner);

    assertEq(newOwner, _rns.ownerOf(id));
    assertEq(newOwner, _rns.getRecord(id).mut.owner);
  }
}
