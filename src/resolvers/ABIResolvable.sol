// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@rns-contracts/interfaces/resolvers/IABIResolver.sol";
import "./BaseVersion.sol";

abstract contract ABIResolvable is IABIResolver, ERC165, BaseVersion {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from version => node => content type => abi
  mapping(uint64 version => mapping(bytes32 node => mapping(uint256 contentType => bytes abi))) internal _versionalAbi;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override(BaseVersion, ERC165) returns (bool) {
    return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IABIResolver
   */
  function ABI(bytes32 node, uint256 contentTypes) external view virtual override returns (uint256, bytes memory) {
    mapping(uint256 contentType => bytes abi) storage abiSet = _versionalAbi[_recordVersion[node]][node];

    for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
      if ((contentType & contentTypes) != 0 && abiSet[contentType].length > 0) {
        return (contentType, abiSet[contentType]);
      }
    }

    return (0, "");
  }

  /**
   * @dev See {IABIResolver-setABI}.
   */
  function _setABI(bytes32 node, uint256 contentType, bytes calldata data) internal {
    if (((contentType - 1) & contentType) != 0) revert InvalidContentType();
    _versionalAbi[_recordVersion[node]][node][contentType] = data;
    emit ABIChanged(node, contentType);
  }
}
