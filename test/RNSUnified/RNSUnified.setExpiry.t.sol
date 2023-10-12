// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";

contract RNSUnified_SetExpiry_Test is RNSUnifiedTest {
  using Strings for *;

  function testGas_AsController_Renew(MintParam calldata mintParam, uint64 renewDuration) external mintAs(_controller) {
    vm.assume(renewDuration > mintParam.duration);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    vm.prank(_controller);
    _rns.renew(id, renewDuration);
  }

  function testGas_AsController_SetExpiry(MintParam calldata mintParam, uint64 renewExpiry)
    external
    mintAs(_controller)
  {
    vm.assume(renewExpiry > block.timestamp + mintParam.duration);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    vm.prank(_controller);
    _rns.setExpiry(id, renewExpiry);
  }

  function testFuzz_RevertWhenAvailable_Renew(MintParam calldata mintParam, uint64 renewDuration)
    external
    mintAs(_controller)
  {
    uint256 id = _toId(_ronId, mintParam.name);
    vm.prank(_controller);
    vm.expectRevert(INSUnified.NameMustBeRegisteredOrInGracePeriod.selector);
    _rns.renew(id, renewDuration);
  }

  function testFuzz_RevertWhenAvailable_SetExpiry(MintParam calldata mintParam, uint64 renewExpiry)
    external
    mintAs(_controller)
  {
    uint256 id = _toId(_ronId, mintParam.name);
    vm.prank(_controller);
    vm.expectRevert(INSUnified.NameMustBeRegisteredOrInGracePeriod.selector);
    _rns.renew(id, renewExpiry);
  }

  function testFuzz_RevertIfNewExpiryLessThanCurrentExpiry_SetExpiry(MintParam calldata mintParam, uint64 renewExpiry)
    external
    mintAs(_controller)
  {
    (uint64 expiry, uint256 id) = _mint(_ronId, mintParam, _noError);
    vm.assume(renewExpiry < expiry);

    vm.prank(_controller);
    vm.expectRevert(INSUnified.ExpiryTimeMustBeLargerThanTheOldOne.selector);
    _rns.setExpiry(id, renewExpiry);
  }

  function testFuzz_RevertIf_AsUnauthorized_Renew(address any, MintParam calldata mintParam, uint64 renewDuration)
    external
    mintAs(_controller)
  {
    vm.assume(any != _controller && any != _admin);
    vm.assume(renewDuration > mintParam.duration);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    bytes memory revertMessage = bytes(
      string.concat(
        "AccessControl: account ", any.toHexString(), " is missing role ", uint256(_rns.CONTROLLER_ROLE()).toHexString()
      )
    );
    vm.prank(any);
    vm.expectRevert(revertMessage);
    _rns.renew(id, renewDuration);
  }

  function testFuzz_RevertIf_AsUnauthorized_SetExpiry(address any, MintParam calldata mintParam, uint64 renewExpiry)
    external
    validAccount(any)
    mintAs(_controller)
  {
    vm.assume(renewExpiry > block.timestamp + mintParam.duration);
    vm.assume(any != _controller && any != _admin);
    (, uint256 id) = _mint(_ronId, mintParam, _noError);

    bytes memory revertMessage = bytes(
      string.concat(
        "AccessControl: account ", any.toHexString(), " is missing role ", uint256(_rns.CONTROLLER_ROLE()).toHexString()
      )
    );
    vm.prank(any);
    vm.expectRevert(revertMessage);
    _rns.setExpiry(id, renewExpiry);
  }
}
