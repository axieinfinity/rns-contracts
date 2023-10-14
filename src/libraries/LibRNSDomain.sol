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
}
