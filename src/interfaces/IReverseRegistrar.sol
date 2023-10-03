// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IReverseRegistrar {
  /**
   * @dev Returns address that the reverse node resolves for.
   * Eg. node namehash('{addr}.addr.reverse') will always resolve for `addr`.
   */
  function getAddress(bytes32 node) external view returns (address);
}
