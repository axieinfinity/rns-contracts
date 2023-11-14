// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title INameChecker
 * @dev The INameChecker interface provides functions for managing and checking substrings and forbidden words in strings.
 */
interface INameChecker {
  /**
   * @dev Emitted when the word range is updated.
   * @param operator The address that updated the word range.
   * @param min The minimum word length allowed.
   * @param max The maximum word length allowed.
   */
  event WordRangeUpdated(address indexed operator, uint8 min, uint8 max);

  /**
   * @dev Emitted when the forbidden words are updated.
   * @param operator The address that updated the forbidden words list.
   * @param wordCount The number of words in the list.
   * @param shouldForbid Boolean indicating whether the specified words should be forbidden.
   */
  event ForbiddenWordsUpdated(address indexed operator, uint256 wordCount, bool shouldForbid);

  /**
   * @dev Returns an array of all substrings of a given string.
   * @param str The input string to analyze.
   * @return subStrings An array of all substrings.
   */
  function getAllSubStrings(string calldata str) external view returns (string[] memory subStrings);

  /**
   * @dev Returns the total number of substrings for a given string length, as well as the minimum and maximum allowed word lengths.
   * @param strlen The length of the input string.
   * @return total The total number of substrings.
   * @return min The minimum word length allowed.
   * @return max The maximum word length allowed.
   */
  function totalSubString(uint256 strlen) external view returns (uint256 total, uint256 min, uint256 max);

  /**
   * @dev Sets a list of forbidden words and specifies whether they should be forbidden.
   * @param packedWords An array of packed word representations.
   * @param shouldForbid Boolean indicating whether the specified words should be forbidden.
   */
  function setForbiddenWords(uint256[] calldata packedWords, bool shouldForbid) external;

  /**
   * @dev Sets a list of forbidden words and specifies whether they should be forbidden.
   * @param words An array of raw words in string representations.
   * @param shouldForbid Boolean indicating whether the specified words should be forbidden.
   */
  function setForbiddenWords(string[] calldata words, bool shouldForbid) external;

  /**
   * @dev Sets the minimum and maximum word lengths allowed.
   * @param min The minimum word length.
   * @param max The maximum word length.
   */
  function setWordRange(uint8 min, uint8 max) external;

  /**
   * @dev Retrieves the current minimum and maximum word lengths allowed.
   * @return min The minimum word length allowed.
   * @return max The maximum word length allowed.
   */
  function getWordRange() external view returns (uint8 min, uint8 max);

  /**
   * @notice Checks if a given name contains any forbidden characters or blacklisted words.
   * @param name The string to check.
   * @return true if the name contains forbidden characters or blacklisted words, false otherwise.
   */
  function forbidden(string calldata name) external view returns (bool);

  /**
   * @notice Checks if a given name is blacklisted.
   * @param name The string to check.
   * @return true if the name is blacklisted, false otherwise.
   */
  function isBlacklistedWord(string calldata name) external view returns (bool);

  /**
   * @notice Checks if a given name contains any invalid characters.
   * requirements:
   * - all characters in name must in range [a-z] or [0-9].
   * @param name The string to check.
   * @return true if the name contains invalid characters, false otherwise.
   */
  function containsInvalidCharacter(string calldata name) external pure returns (bool);

  /**
   * @dev Packs a string into a single word representation.
   * @param str The string to be packed.
   * @notice Returns `uint256(0)` if the length is zero or greater than 31.
   * @return packed The packed value of the input string.
   */
  function pack(string memory str) external pure returns (uint256 packed);

  /**
   * @dev Packs an array of strings into their single word representations.
   * @param strs The array of strings to be packed.
   * @notice Returns an array of packed values, along with the minimum and maximum string lengths.
   * @return packeds An array containing the packed values of the input strings.
   */
  function packBulk(string[] memory strs) external pure returns (uint256[] memory packeds);
}
