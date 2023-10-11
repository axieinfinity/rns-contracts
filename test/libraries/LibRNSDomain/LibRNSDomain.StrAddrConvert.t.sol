// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { LibRNSDomain } from "src/libraries/LibRNSDomain.sol";

contract LibRNSDomain_StrAddrConvert_Test is Test {
  function test_AddressToString(address addr) public {
    string memory expected = withoutHexPrefix(Strings.toHexString(addr));
    string memory actual = LibRNSDomain.toString(addr);
    assertEq(expected, actual);
  }

  function test_StringToAddress(address expected) public {
    string memory stringifiedAddr = withoutHexPrefix(Strings.toHexString(expected));
    address actual = LibRNSDomain.parseAddr(stringifiedAddr);
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