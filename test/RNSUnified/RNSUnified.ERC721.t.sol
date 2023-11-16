// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_ERC721_Test is RNSUnifiedTest {
  function test_TokenMetadata() external {
    assertEq(_rns.name(), "Ronin Name Service");
    assertEq(_rns.symbol(), "RNS");
  }

  function testFuzz_WhenExpired_RevokeOwnership_ownerOf(MintParam calldata mintParam) external mintAs(_controller) {
    (uint64 expiry, uint256 id) = _mint(_ronId, mintParam, _noError);
    _warpToExpire(expiry);
    assertEq(_rns.ownerOf(id), address(0x00));
  }

  function testFuzz_WhenExpired_RevokeApproval_getApproved(address approved, MintParam calldata mintParam)
    external
    validAccount(approved)
    mintAs(_controller)
  {
    vm.assume(approved != mintParam.owner && approved != _admin);
    (uint64 expiry, uint256 id) = _mint(_ronId, mintParam, _noError);
    vm.prank(mintParam.owner);
    _rns.setApprovalForAll(approved, true);
    _warpToExpire(expiry);
    address actualApproved = _rns.getApproved(id);
    assertEq(actualApproved, address(0x00));
  }

  function testFuzz_UpdateRecordOwner_transferFrom(address newOwner, MintParam calldata mintParam)
    external
    validAccount(newOwner)
    mintAs(_controller)
  {
    vm.assume(newOwner != _admin && newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);
    vm.prank(mintParam.owner);
    _rns.transferFrom(mintParam.owner, newOwner, id);
    INSUnified.Record memory record = _rns.getRecord(id);
    assertEq(record.mut.owner, newOwner);
  }

  function testFuzz_WhenTransfered_LostProtected(address newOwner, MintParam calldata mintParam)
    external
    validAccount(newOwner)
    mintAs(_controller)
  {
    vm.assume(newOwner != mintParam.owner);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    uint256[] memory ids = new uint256[](1);
    ids[0] = id;
    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, true);

    INSUnified.Record memory record = _rns.getRecord(id);
    assertTrue(record.mut.protected);

    vm.prank(mintParam.owner);
    _rns.transferFrom(mintParam.owner, newOwner, id);

    record = _rns.getRecord(id);
    assertFalse(record.mut.protected);
  }
}
