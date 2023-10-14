// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseVersion } from "./BaseVersion.sol";
import { INameResolver } from "@rns-contracts/interfaces/resolvers/INameResolver.sol";

abstract contract NameResolvable is INameResolver, BaseVersion {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev mapping from version => node => name
  mapping(uint64 version => mapping(bytes32 node => string name)) internal _versionName;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
    return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc INameResolver
   */
  function name(bytes32 node) public view virtual override returns (string memory) {
    return _versionName[_recordVersion[node]][node];
  }

  /**
   * @dev See {INameResolver-setName}.
   */
  function _setName(bytes32 node, string memory newName) internal virtual {
    _versionName[_recordVersion[node]][node] = newName;
    emit NameChanged(node, newName);
  }
}
