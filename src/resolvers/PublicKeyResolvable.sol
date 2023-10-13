// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseVersion } from "./BaseVersion.sol";
import { IPublicKeyResolver } from "@rns-contracts/interfaces/resolvers/IPublicKeyResolver.sol";

abstract contract PublicKeyResolvable is BaseVersion, IPublicKeyResolver {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from version => node => public key
  mapping(uint64 version => mapping(bytes32 node => PublicKey publicKey)) internal _versionPublicKey;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
    return interfaceID == type(IPublicKeyResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @dev See {IPublicKeyResolver-pubkey}.
   */
  function pubkey(bytes32 node) external view virtual override returns (bytes32 x, bytes32 y) {
    uint64 currentRecordVersion = _recordVersion[node];
    return (_versionPublicKey[currentRecordVersion][node].x, _versionPublicKey[currentRecordVersion][node].y);
  }

  /**
   * @dev See {IPublicKeyResolver-setPubkey}.
   */
  function _setPubkey(bytes32 node, bytes32 x, bytes32 y) internal virtual {
    _versionPublicKey[_recordVersion[node]][node] = PublicKey(x, y);
    emit PubkeyChanged(node, x, y);
  }
}
