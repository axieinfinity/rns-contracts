// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RNSUnified.t.sol";
import { LibString } from "solady/utils/LibString.sol";

contract RNSUnified_NameHash_Test is RNSUnifiedTest {
  using LibString for *;

  function testGas_namehash(string calldata domainName) external view {
    _rns.namehash(domainName);
  }

  function testFuzz_namehash(string memory domainName) external {
    vm.assume(bytes(domainName).length != 0);
    vm.assume(bytes1(bytes(domainName)[bytes(domainName).length - 1]) != 0x2e);
    vm.assume(domainName.is7BitASCII());
    domainName = domainName.lower();

    string[] memory commandInput = new string[](4);
    commandInput[0] = "cast";
    commandInput[1] = "namehash";
    commandInput[2] = "--";
    commandInput[3] = domainName;
    bytes memory result;
    try vm.ffi(commandInput) returns (bytes memory res) {
      result = res;
    } catch {
      vm.assume(result.length != 0);
    }
    bytes32 expected = bytes32(result);

    bytes32 actual = bytes32(_rns.namehash(domainName));
    assertEq(expected, actual);
  }

  function _boundString(string memory str) internal pure returns (string memory validStr) {
    bytes1 b;
    uint256 bounded;
    uint256 length = bytes(str).length;
    for (uint256 i; i < length;) {
      b = bytes(str)[i];
      bounded = _bound(uint8(b), 97, 122);
      bytes(str)[i] = bytes1(bytes32(bounded));

      unchecked {
        ++i;
      }
    }

    validStr = str;
  }
}
