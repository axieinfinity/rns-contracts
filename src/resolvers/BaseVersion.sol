// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/resolvers/IVersionResolver.sol";

abstract contract BaseVersion is IVersionResolver, ERC165 {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from node => version
  mapping(bytes32 node => uint64 version) internal _recordVersion;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
    return interfaceID == type(IVersionResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IVersionResolver
   */
  function recordVersions(bytes32 node) external view returns (uint64) {
    return _recordVersion[node];
  }

  /**
   * @dev See {IVersionResolver-clearRecords}.
   */
  function _clearRecords(bytes32 node) internal {
    unchecked {
      emit VersionChanged(node, ++_recordVersion[node]);
    }
  }
}
