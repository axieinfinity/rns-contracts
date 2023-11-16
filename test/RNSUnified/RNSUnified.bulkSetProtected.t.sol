// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_BulkSetProtected_Test is RNSUnifiedTest {
  using LibModifyingField for ModifyingField;

  uint256 public constant MAX_FUZZ_INPUT = 100;

  modifier boundFuzzArrLength(uint256 length) {
    vm.assume(length <= MAX_FUZZ_INPUT);
    _;
  }

  function testFuzz_RevertWhenNotMinted_bulkSetProtected(bool protected, MintParam calldata mintParam) external {
    vm.skip(true);
    uint256 id = _toId(_ronId, mintParam.name);
    uint256[] memory ids = new uint256[](1);
    ids[0] = id;
    vm.expectRevert(INSUnified.Unexists.selector);
    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, protected);
  }

  function testGas_WhenMinted_AsProtectedSettler_bulkSetProtected(MintParam[] calldata mintParams)
    external
    mintAs(_controller)
    boundFuzzArrLength(mintParams.length)
  {
    uint256[] memory ids = _mintBulk(mintParams);

    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, true);

    vm.pauseGasMetering();
    for (uint256 i; i < ids.length;) {
      assertTrue(_rns.getRecord(ids[i]).mut.protected);

      unchecked {
        ++i;
      }
    }
    vm.resumeGasMetering();
  }

  function testGas_WhenMinted_AsProtectedSettler_bulkSetUnprotected(MintParam[] calldata mintParams)
    external
    mintAs(_controller)
    boundFuzzArrLength(mintParams.length)
  {
    uint256[] memory ids = _mintBulk(mintParams);

    vm.pauseGasMetering();
    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, true);

    vm.resumeGasMetering();
    vm.prank(_protectedSettler);
    _rns.bulkSetProtected(ids, false);
    vm.pauseGasMetering();

    for (uint256 i; i < ids.length;) {
      assertFalse(_rns.getRecord(ids[i]).mut.protected);

      unchecked {
        ++i;
      }
    }
    vm.resumeGasMetering();
  }
}
