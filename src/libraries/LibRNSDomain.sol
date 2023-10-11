//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library LibRNSDomain {
  error InvalidStringLength();
  error InvalidCharacter(bytes1 char);
  error TotalSubStringTooLarge(uint256 total);

  /**
   * @dev Struct representing a word range with minimum and maximum word lengths.
   */
  struct WordRange {
    uint8 min;
    uint8 max;
  }

  /// @dev Value equals to namehash('ron')
  uint256 internal constant RON_ID = 0xba69923fa107dbf5a25a073a10b7c9216ae39fbadc95dc891d460d9ae315d688;
  /// @dev Value equals to namehash('addr.reverse')
  uint256 internal constant ADDR_REVERSE_ID = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
  uint256 internal constant MAX_SUBSTRING_SIZE = type(uint16).max;
  /// @dev Lookup constant for method. See more detail at https://eips.ethereum.org/EIPS/eip-181
  bytes32 internal constant LOOKUP = 0x3031323334353637383961626364656600000000000000000000000000000000;

  /**
   * @dev Calculate the corresponding id given parentId and label.
   */
  function toId(uint256 parentId, string memory label) internal pure returns (uint256 id) {
    assembly ("memory-safe") {
      mstore(0x0, parentId)
      mstore(0x20, keccak256(add(label, 32), mload(label)))
      id := keccak256(0x0, 64)
    }
  }

  function hashLabel(string memory label) internal pure returns (bytes32 hashed) {
    assembly ("memory-safe") {
      hashed := keccak256(add(label, 32), mload(label))
    }
  }

  /**
   * @dev Calculate the RNS namehash of a str.
   */
  function namehash(string memory str) public pure returns (bytes32 hashed) {
    // notice: this method is case-sensitive, ensure the string is lowercased before calling this method
    assembly ("memory-safe") {
      // load str length
      let len := mload(str)
      // returns bytes32(0x0) if length is zero
      if iszero(iszero(len)) {
        let hashedLen
        // compute pointer to str[0]
        let head := add(str, 32)
        // compute pointer to str[length - 1]
        let tail := add(head, sub(len, 1))
        // cleanup dirty bytes if contains any
        mstore(0x0, 0)
        // loop backwards from `tail` to `head`
        for { let i := tail } iszero(lt(i, head)) { i := sub(i, 1) } {
          // check if `i` is `head`
          let isHead := eq(i, head)
          // check if `str[i-1]` is "."
          // `0x2e` == bytes1(".")
          let isDotNext := eq(shr(248, mload(sub(i, 1))), 0x2e)
          if or(isHead, isDotNext) {
            // size = distance(length, i) - hashedLength + 1
            let size := add(sub(sub(tail, i), hashedLen), 1)
            mstore(0x20, keccak256(i, size))
            mstore(0x0, keccak256(0x0, 64))
            // skip "." thereby + 1
            hashedLen := add(hashedLen, add(size, 1))
          }
        }
      }
      hashed := mload(0x0)
    }
  }

  /**
   * @dev Retrieves all possible substrings within a given string based on a specified word range.
   * @param str The input string to analyze.
   * @param wordRange The word range specifying the minimum and maximum word lengths.
   * @return subStrings An array of all possible substrings within the input string.
   */
  function getAllSubStrings(string calldata str, WordRange memory wordRange)
    internal
    pure
    returns (string[] memory subStrings)
  {
    unchecked {
      uint256 length = bytes(str).length;
      (uint256 total, uint256 min, uint256 max) = totalSubString(length, wordRange);
      subStrings = new string[](total);
      uint256 idx;
      uint256 bLength;

      for (uint256 i; i < length; ++i) {
        bLength = Math.min(i + max, length);

        for (uint256 j = i + min; j <= bLength; ++j) {
          subStrings[idx++] = str[i:j];
        }
      }
    }
  }

  /**
   * @dev Calculates the total number of possible substrings within a given string length based on a specified word range.
   * @param len The length of the input string.
   * @param wordRange The word range specifying the minimum and maximum word lengths.
   * @return total The total number of possible substrings.
   * @return min The minimum word length allowed.
   * @return max The maximum word length allowed.
   */
  function totalSubString(uint256 len, WordRange memory wordRange)
    internal
    pure
    returns (uint256 total, uint256 min, uint256 max)
  {
    unchecked {
      min = Math.min(wordRange.min, len);
      max = Math.min(wordRange.max, len);
      uint256 range = max - min;
      // `(range + 1)` represents the number of possible substring lengths in `range`.
      // `(strlen - min + 1)` represents the number of possible starting positions for substrings with a minimum length of `min`.
      total = (range + 1) * (len - min + 1) - (((range + 1) * range) >> 1);
      if (total > MAX_SUBSTRING_SIZE) revert TotalSubStringTooLarge(total);
    }
  }

  /**
   * @dev Returns the length of a given string
   *
   * @param s The string to measure the length of
   * @return The length of the input string
   */
  function strlen(string memory s) internal pure returns (uint256) {
    unchecked {
      uint256 len;
      uint256 i = 0;
      uint256 bytelength = bytes(s).length;
      for (len = 0; i < bytelength; len++) {
        bytes1 b = bytes(s)[i];
        if (b < 0x80) {
          i += 1;
        } else if (b < 0xE0) {
          i += 2;
        } else if (b < 0xF0) {
          i += 3;
        } else if (b < 0xF8) {
          i += 4;
        } else if (b < 0xFC) {
          i += 5;
        } else {
          i += 6;
        }
      }
      return len;
    }
  }

  /**
   * @dev Converts an address to string.
   */
  function toString(address addr) internal pure returns (string memory stringifiedAddr) {
    assembly ("memory-safe") {
      mstore(stringifiedAddr, 40)
      let ptr := add(stringifiedAddr, 0x20)
      for { let i := 40 } gt(i, 0) { } {
        i := sub(i, 1)
        mstore8(add(i, ptr), byte(and(addr, 0xf), LOOKUP))
        addr := div(addr, 0x10)

        i := sub(i, 1)
        mstore8(add(i, ptr), byte(and(addr, 0xf), LOOKUP))
        addr := div(addr, 0x10)
      }
    }
  }

  /**
   * @dev Converts string to address.
   * Reverts if the string length is not equal to 40.
   */
  function parseAddr(string memory stringifiedAddr) internal pure returns (address) {
    unchecked {
      if (bytes(stringifiedAddr).length != 40) revert InvalidStringLength();
      uint160 addr;
      for (uint256 i = 0; i < 40; i += 2) {
        addr *= 0x100;
        addr += uint160(_hexCharToDec(bytes(stringifiedAddr)[i])) * 0x10;
        addr += _hexCharToDec(bytes(stringifiedAddr)[i + 1]);
      }
      return address(addr);
    }
  }

  /**
   * @dev Converts a hex char (0-9, a-f, A-F) to decimal number.
   * Reverts if the char is invalid.
   */
  function _hexCharToDec(bytes1 c) private pure returns (uint8 r) {
    unchecked {
      if ((bytes1("a") <= c) && (c <= bytes1("f"))) r = uint8(c) - 87;
      else if ((bytes1("A") <= c) && (c <= bytes1("F"))) r = uint8(c) - 55;
      else if ((bytes1("0") <= c) && (c <= bytes1("9"))) r = uint8(c) - 48;
      else revert InvalidCharacter(c);
    }
  }
}
