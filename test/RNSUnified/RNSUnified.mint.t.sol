// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_Mint_Test is RNSUnifiedTest {
  function testGas_AsController_mint(MintParam calldata mintParam) external mintAs(_controller) {
    _mint(_ronId, mintParam, _noError);
  }

  function testGas_AsAdmin_mint(MintParam calldata mintParam) external mintAs(_admin) {
    _mint(_ronId, mintParam, _noError);
  }

  function testFuzz_AsParentApproved_mint(address approved, MintParam calldata mintParam)
    external
    validAccount(approved)
    mintAs(approved)
  {
    vm.assume(_admin != approved);
    vm.prank(_admin);
    _rns.approve(approved, _ronId);
    _mint(_ronId, mintParam, _noError);
  }

  function testFuzz_RevertWhenPaused_AsController_mint(MintParam calldata mintParam) external mintAs(_controller) {
    vm.prank(_pauser);
    _rns.pause();
    _mint(_ronId, mintParam, Error(true, "Pausable: paused"));
  }

  function testFuzz_RevertWhenRonIdTransfered_AsController_mint(address newAdmin, MintParam calldata mintParam)
    external
    mintAs(_controller)
    validAccount(newAdmin)
  {
    vm.assume(_admin != newAdmin && newAdmin != _controller);
    vm.prank(_admin);
    _rns.safeTransferFrom(_admin, newAdmin, _ronId);
    _mint(_ronId, mintParam, Error(true, abi.encodeWithSelector(INSUnified.Unauthorized.selector)));
  }

  function testFuzz_RevertIfUnauthorized_mint(address any, MintParam calldata mintParam) external mintAs(any) {
    vm.assume(any != _admin && any != _controller);
    _mint(_ronId, mintParam, Error(true, abi.encodeWithSelector(INSUnified.Unauthorized.selector)));
  }

  function testFuzz_AsController_RevertWhenNotExpired_Remint(address otherOwner, MintParam memory mintParam)
    external
    mintAs(_controller)
  {
    _mint(_ronId, mintParam, _noError);
    mintParam.owner = otherOwner;
    _mint(_ronId, mintParam, Error(true, abi.encodeWithSelector(INSUnified.Unavailable.selector)));
  }

  function testFuzz_AsController_WhenExpired_Remint(MintParam calldata mintParam) external mintAs(_controller) {
    vm.assume(block.timestamp + mintParam.duration < _ronExpiry);
    (uint64 expiry, uint256 id) = _mint(_ronId, mintParam, _noError);
    assertFalse(_rns.available(id));
    _warpToExpire(expiry);
    assertTrue(_rns.available(id));
    _mint(_ronId, mintParam, _noError);
  }

  function testFuzz_AsController_RevertWhenControllerUnapproved_mint(MintParam calldata mintParam)
    external
    mintAs(_controller)
  {
    vm.prank(_admin);
    _rns.setApprovalForAll(_controller, false);
    _mint(_ronId, mintParam, Error(true, abi.encodeWithSelector(INSUnified.Unauthorized.selector)));
  }

  function testFuzz_WhenRemint_LostProtected(MintParam calldata mintParam) external mintAs(_controller) {
    (uint64 expiry, uint256 id) = _mint(_ronId, mintParam, _noError);
    uint256[] memory ids = new uint256[](1);
    ids[0] = id;

    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, true);

    _warpToExpire(expiry);
    _mint(_ronId, mintParam, _noError);

    assertFalse(_rns.getRecord(id).mut.protected);
  }
}
