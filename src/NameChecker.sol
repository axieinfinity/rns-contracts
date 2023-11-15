// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Math, LibSubString } from "./libraries/LibSubString.sol";
import { INameChecker } from "./interfaces/INameChecker.sol";

contract NameChecker is Initializable, AccessControlEnumerable, INameChecker {
  using LibSubString for *;
  using BitMaps for BitMaps.BitMap;

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  LibSubString.WordRange internal _wordRange;
  BitMaps.BitMap internal _forbiddenWordMap;

  constructor() payable {
    _disableInitializers();
  }

  function initialize(address admin, uint8 min, uint8 max) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setWordRange(min, max);
  }

  /**
   * @inheritdoc INameChecker
   */
  function getWordRange() external view returns (uint8 min, uint8 max) {
    LibSubString.WordRange memory wordRange = _wordRange;
    return (wordRange.min, wordRange.max);
  }

  /**
   * @inheritdoc INameChecker
   */
  function setWordRange(uint8 min, uint8 max) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setWordRange(min, max);
  }

  /**
   * @inheritdoc INameChecker
   */
  function forbidden(string calldata name) public view returns (bool) {
    return containsInvalidCharacter(name) || containsBlacklistedWord(name);
  }

  /**
   * @inheritdoc INameChecker
   */
  function containsBlacklistedWord(string calldata name) public view returns (bool) {
    uint256 length = bytes(name).length;
    bytes1 char;
    uint256 i;
    uint256 j;

    unchecked {
      for (i; i < length; i++) {
        char = bytes(name)[i];

        if (_isAlphabet(char)) {
          for (j = i + 1; j < length; j++) {
            if (!_isAlphabet(bytes(name)[j])) {
              break;
            }
          }

          if (_forbiddenWordMap.get(pack(name[i:j]))) return true;
          i = j;
        }
      }
    }

    return false;
  }

  /**
   * @inheritdoc INameChecker
   */
  function containsInvalidCharacter(string calldata name) public pure returns (bool) {
    unchecked {
      bytes1 char;
      bytes memory bName = bytes(name);
      uint256 length = bName.length;

      uint256 tail = length - 1;
      // Check if the name is empty or starts or ends with a hyphen (-)
      if (length == 0 || bName[0] == 0x2d || bName[tail] == 0x2d) return true;

      for (uint256 i; i < length; ++i) {
        char = bName[i];
        if (char == 0x2d) {
          // Check consecutive hyphens
          if (i != tail && bName[i + 1] == 0x2d) return true;
        }
        // Check for invalid character (not (-) || [0-9] || [a-z])
        else if (!(_isNumber(char) || _isAlphabet(char))) {
          return true;
        }
      }

      return false;
    }
  }

  /**
   * @inheritdoc INameChecker
   */
  function pack(string memory str) public pure returns (uint256 packed) {
    assembly ("memory-safe") {
      // We don't need to zero right pad the string,
      // since this is our own custom non-standard packing scheme.
      packed :=
        mul(
          // Load the length and the bytes.
          mload(add(str, 0x1f)),
          // `length != 0 && length < 32`. Abuses underflow.
          // Assumes that the length is valid and within the block gas limit.
          lt(sub(mload(str), 1), 0x1f)
        )
    }
  }

  /**
   * @inheritdoc INameChecker
   */
  function packBulk(string[] memory strs) public pure returns (uint256[] memory packeds) {
    uint256 length = strs.length;
    packeds = new uint256[](length);

    for (uint256 i; i < length;) {
      packeds[i] = pack(strs[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @inheritdoc INameChecker
   */
  function setForbiddenWords(string[] calldata words, bool shouldForbid) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256[] memory packedWords = packBulk(words);
    _setForbiddenWords(packedWords, shouldForbid);
  }

  /**
   * @inheritdoc INameChecker
   */
  function setForbiddenWords(uint256[] calldata packedWords, bool shouldForbid) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setForbiddenWords(packedWords, shouldForbid);
  }

  /**
   * @inheritdoc INameChecker
   */
  function totalSubString(uint256 strlen) public view returns (uint256 total, uint256 min, uint256 max) {
    (total, min, max) = strlen.totalSubString(_wordRange);
  }

  /**
   * @inheritdoc INameChecker
   */
  function getAllSubStrings(string calldata str) public view returns (string[] memory subStrings) {
    subStrings = str.getAllSubStrings(_wordRange);
  }

  /**
   * @dev Set the forbidden status of packed words.
   * @param packedWords An array of packed word representations.
   * @param shouldForbid A boolean flag indicating whether to forbid or unforbid the words.
   * @notice It ensures that packed words are not zero, indicating their validity.
   * @notice Emits a `ForbiddenWordsUpdated` event upon successful execution.
   */
  function _setForbiddenWords(uint256[] memory packedWords, bool shouldForbid) internal {
    uint256 length = packedWords.length;
    uint256 strlen;
    uint256 max;
    uint256 min = type(uint256).max;

    for (uint256 i; i < length;) {
      require(packedWords[i] != 0, "NameChecker: invalid packed word");
      strlen = packedWords[i] >> 0xf8;
      min = Math.min(min, strlen);
      max = Math.max(max, strlen);
      _forbiddenWordMap.setTo(packedWords[i], shouldForbid);

      unchecked {
        ++i;
      }
    }

    if (shouldForbid) {
      LibSubString.WordRange memory wordRange = _wordRange;
      min = Math.min(min, wordRange.min);
      max = Math.max(max, wordRange.max);
      if (!(min == wordRange.min && max == wordRange.max)) _setWordRange(uint8(min), uint8(max));
    }

    emit ForbiddenWordsUpdated(_msgSender(), length, shouldForbid);
  }

  /**
   * @dev Set the allowed word length range.
   * @param min The minimum word length allowed.
   * @param max The maximum word length allowed.
   * @notice The minimum word length must be greater than 0, and it must not exceed the maximum word length.
   */
  function _setWordRange(uint8 min, uint8 max) internal {
    require(min != 0 && min <= max, "NameChecker: min word length > max word length");
    _wordRange = LibSubString.WordRange(min, max);
    emit WordRangeUpdated(_msgSender(), min, max);
  }

  /// @dev Returns whether a char is in [a-z]
  function _isAlphabet(bytes1 char) internal pure returns (bool) {
    // [0x61, 0x7a] => [a-z]
    return char >= 0x61 && char <= 0x7a;
  }

  /// @dev Returns whether a char is number [0-9]
  function _isNumber(bytes1 char) internal pure returns (bool) {
    // [0x30, 0x39] => [0-9]
    return char >= 0x30 && char <= 0x39;
  }
}
