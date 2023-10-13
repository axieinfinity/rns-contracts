// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "src/libraries/LibStrAddrConvert.sol";

contract LibStrAddrConvertTest is Test {
  function test_AddressToString(address addr) public {
    string memory expected = withoutHexPrefix(Strings.toHexString(addr));
    string memory actual = LibStrAddrConvert.toString(addr);
    assertEq(expected, actual);
  }

  function test_StringToAddress(address expected) public {
    string memory stringifiedAddr = withoutHexPrefix(Strings.toHexString(expected));
    address actual = LibStrAddrConvert.parseAddr(stringifiedAddr);
    assertEq(expected, actual);
  }

  function withoutHexPrefix(string memory str) public pure returns (string memory) {
    if (bytes(str)[0] == bytes1("0") && bytes(str)[1] == bytes1("x")) {
      uint256 length = bytes(str).length;
      bytes memory out = new bytes(length - 2);
      for (uint256 i = 2; i < length; i++) {
        out[i - 2] = bytes(str)[i];
      }
      return string(out);
    }
    return str;
  }
}
