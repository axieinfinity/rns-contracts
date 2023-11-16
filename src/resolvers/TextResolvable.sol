// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseVersion } from "./BaseVersion.sol";
import { ITextResolver } from "../interfaces/resolvers/ITextResolver.sol";

abstract contract TextResolvable is BaseVersion, ITextResolver {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;
  /// @dev Mapping from version => node => key => text
  mapping(uint64 version => mapping(bytes32 node => mapping(string key => string text))) internal _versionText;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
    return interfaceID == type(ITextResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc ITextResolver
   */
  function text(bytes32 node, string calldata key) external view virtual override returns (string memory) {
    return _versionText[_recordVersion[node]][node][key];
  }

  /**
   * @dev See {ITextResolver-setText}.
   */
  function _setText(bytes32 node, string calldata key, string calldata value) internal virtual {
    _versionText[_recordVersion[node]][node][key] = value;
    emit TextChanged(node, key, key, value);
  }
}
