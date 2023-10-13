// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibRNSDomain {
  /// @dev Value equals to namehash('ron')
  uint256 internal constant RON_ID = 0xba69923fa107dbf5a25a073a10b7c9216ae39fbadc95dc891d460d9ae315d688;
  /// @dev Value equals to namehash('addr.reverse')
  uint256 internal constant ADDR_REVERSE_ID = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

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

  /**
   * @dev Calculates the hash of the label.
   */
  function hashLabel(string memory label) internal pure returns (bytes32 hashed) {
    assembly ("memory-safe") {
      hashed := keccak256(add(label, 32), mload(label))
    }
  }

  /**
   * @dev Calculate the RNS namehash of a str.
   */
  function namehash(string memory str) internal pure returns (bytes32 hashed) {
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
}
