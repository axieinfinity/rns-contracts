// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/resolvers/IContentHashResolver.sol";
import "./BaseVersion.sol";

abstract contract ContentHashResolvable is IContentHashResolver, ERC165, BaseVersion {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from version => node => content hash
  mapping(uint64 version => mapping(bytes32 node => bytes contentHash)) internal _versionContentHash;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override(BaseVersion, ERC165) returns (bool) {
    return interfaceID == type(IContentHashResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IContentHashResolver
   */
  function contentHash(bytes32 node) external view virtual override returns (bytes memory) {
    return _versionContentHash[_recordVersion[node]][node];
  }

  /**
   * @dev See {IContentHashResolver-setContentHash}.
   */
  function _setContentHash(bytes32 node, bytes calldata hash) internal {
    _versionContentHash[_recordVersion[node]][node] = hash;
    emit ContentHashChanged(node, hash);
  }
}
