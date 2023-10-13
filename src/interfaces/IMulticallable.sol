// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice To multi-call to a specified contract which has multicall interface:
 *
 * ```solidity
 * interface IMock is IMulticallable {
 *   function foo() external;
 *   function bar() external;
 * }
 *
 * bytes[] memory calldatas = new bytes[](2);
 * calldatas[0] = abi.encodeCall(IMock.foo,());
 * calldatas[1] = abi.encodeCall(IMock.bar,());
 * IMock(target).multicall(calldatas);
 * ```
 */
interface IMulticallable {
  /**
   * @dev Executes bulk action to the original contract.
   * Reverts if there is a single call failed.
   *
   * @param data The calldata to original contract.
   *
   */
  function multicall(bytes[] calldata data) external returns (bytes[] memory results);

  /**
   * @dev Executes bulk action to the original contract.
   *
   * @param requireSuccess Flag to indicating whether the contract reverts if there is a single call failed.
   * @param data The calldata to original contract.
   *
   */
  function tryMulticall(bool requireSuccess, bytes[] calldata data) external returns (bytes[] memory results);
}
