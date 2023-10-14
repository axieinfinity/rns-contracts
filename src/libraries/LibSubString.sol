// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LibSubString
 * @dev A library for working with substrings and word ranges in strings.
 */
library LibSubString {
  error TotalSubStringTooLarge(uint256 total);
  /**
   * @dev Struct representing a word range with minimum and maximum word lengths.
   */

  struct WordRange {
    uint8 min;
    uint8 max;
  }

  uint256 public constant MAX_SUBSTRING_SIZE = type(uint16).max;

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
}
