// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_Reclaim_Test is RNSUnifiedTest {
  using LibModifyingField for *;

  function test_WhenMintedAndTransferedToNewOwner_AsController_ReclaimOwnership_reclaim(
    address newOwner,
    MintParam calldata mintParam
  ) external mintAs(_controller) reclaimAs(_controller) validAccount(newOwner) {
    vm.assume(newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    vm.prank(mintParam.owner);
    _rns.transferFrom(mintParam.owner, newOwner, id);

    assertEq(newOwner, _rns.ownerOf(id));
    assertEq(newOwner, _rns.getRecord(id).mut.owner);

    _reclaim(id, mintParam.owner);
  }

  function test_WhenMinted_AsParentOwner_ReclaimOwnership_reclaim(address newOwner, MintParam calldata mintParam)
    external
    mintAs(_controller)
    reclaimAs(_admin)
    validAccount(newOwner)
  {
    vm.assume(newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    _reclaim(id, newOwner);
  }

  function test_WhenMinted_AsApproved_ReclaimOwnership_reclaim(
    address approved,
    address newOwner,
    MintParam calldata mintParam
  ) external mintAs(_controller) reclaimAs(approved) validAccount(approved) validAccount(newOwner) {
    vm.assume(approved != mintParam.owner);
    vm.assume(newOwner != mintParam.owner);

    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    vm.prank(mintParam.owner);
    _rns.approve(approved, id);

    _reclaim(id, newOwner);
  }
}
