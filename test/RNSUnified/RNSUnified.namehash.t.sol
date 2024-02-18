// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";
import { LibString as SoladyLibString } from "solady/utils/LibString.sol";

contract RNSUnified_NameHash_Test is RNSUnifiedTest {
  using SoladyLibString for *;

  function testGas_namehash(string calldata domainName) external view {
    _rns.namehash(domainName);
  }

  function testFuzz_namehash(string memory domainName) external {
    vm.assume(domainName.is7BitASCII());
    vm.assume(bytes(domainName).length != 0);
    vm.assume(bytes1(bytes(domainName)[bytes(domainName).length - 1]) != 0x2e);
    domainName = domainName.lower();

    bytes32 expected = _tryExecCastNameHash(domainName);
    bytes32 actual = bytes32(_rns.namehash(domainName));
    assertEq(expected, actual, "expected != actual");
  }

  function testFuzz_WithDepth_namehash(string[] calldata names) external {
    vm.skip(true);
    string memory domainName = "ron";
    for (uint256 i; i < names.length;) {
      vm.assume(names[i].is7BitASCII());
      domainName = string.concat(names[i].lower(), ".", domainName);
      unchecked {
        ++i;
      }
    }

    console2.log("domainName", domainName);

    bytes32 actual = _rns.namehash(domainName);
    bytes32 expected = _tryExecCastNameHash(domainName);
    assertEq(expected, actual, "expected != actual");
  }

  function testConcrete_namehash(MintParam memory mintParam) external mintAs(_admin) mintGasOff {
    vm.skip(true);
    // script: `cast namehash ron`
    bytes32 precomputedRonNode = 0xba69923fa107dbf5a25a073a10b7c9216ae39fbadc95dc891d460d9ae315d688;
    // script: `cast namehash duke.ron`
    bytes32 precomputedDukeRonNode = 0x4467e296cabb66ee07d345db56cf81360336f0e6eafb97957d0c2ab9082adbd3;
    // script: `cast namehash vip.duke.ron`
    bytes32 precomputedVipDukeRonNode = 0x7dfa57d9b2429bb181ddacbbc46bcc286a485f9e691bc64a170ad976c9199a18;
    // script: `cast namehash abc.def.xyz.ron`
    bytes32 precomputedAbcDefXyzRonNode = 0xfa0b23ea2345da3c215b2ce4a5bb2139c5ed05616b14e7f1d535813acce45b42;
    // script: `cast namehash �.ron`
    bytes32 precomputedUnicodeRonNode = 0xb302a636e6ceb332cbd5d0c9f2dc9be5d81975d2ce808400168856f186fee057;

    mintParam.owner = _controller;
    mintParam.name = "duke";
    (, uint256 dukeRonId) = _mint(_ronId, mintParam, _noError);
    mintParam.name = "vip";
    (, uint256 vipDukeRonId) = _mint(dukeRonId, mintParam, _noError);

    assertEq(bytes32(_ronId), precomputedRonNode);
    assertEq(bytes32(dukeRonId), precomputedDukeRonNode);
    assertEq(bytes32(vipDukeRonId), precomputedVipDukeRonNode);
    assertEq(_rns.namehash("ron"), precomputedRonNode);
    assertEq(_rns.namehash("duke.ron"), precomputedDukeRonNode);
    assertEq(_rns.namehash(unicode"�.ron"), precomputedUnicodeRonNode);
    assertEq(_rns.namehash("vip.duke.ron"), precomputedVipDukeRonNode);
    assertEq(_rns.namehash("abc.def.xyz.ron"), precomputedAbcDefXyzRonNode);
  }

  function _tryExecCastNameHash(string memory str) internal returns (bytes32 expected) {
    string[] memory commandInput = new string[](4);
    commandInput[0] = "cast";
    commandInput[1] = "namehash";
    commandInput[2] = "--";
    commandInput[3] = str;
    bytes memory result;
    try vm.ffi(commandInput) returns (bytes memory res) {
      result = res;
    } catch {
      vm.assume(result.length != 0);
    }
    expected = bytes32(result);
  }
}
