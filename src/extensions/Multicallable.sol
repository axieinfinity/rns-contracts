// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IMulticallable } from "@rns-contracts/interfaces/IMulticallable.sol";
import { ErrorHandler } from "@rns-contracts/libraries/ErrorHandler.sol";

abstract contract Multicallable is ERC165, IMulticallable {
  using ErrorHandler for bool;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
    return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IMulticallable
   */
  function multicall(bytes[] calldata data) public override returns (bytes[] memory results) {
    return _tryMulticall(true, data);
  }

  /**
   * @inheritdoc IMulticallable
   */
  function tryMulticall(bool requireSuccess, bytes[] calldata data) public override returns (bytes[] memory results) {
    return _tryMulticall(requireSuccess, data);
  }

  /**
   * @dev See {IMulticallable-tryMulticall}.
   */
  function _tryMulticall(bool requireSuccess, bytes[] calldata data) internal returns (bytes[] memory results) {
    uint256 length = data.length;
    results = new bytes[](length);

    bool success;
    bytes memory result;

    for (uint256 i; i < length;) {
      (success, result) = address(this).delegatecall(data[i]);
      if (requireSuccess) success.handleRevert(result);
      results[i] = result;

      unchecked {
        ++i;
      }
    }
  }
}
