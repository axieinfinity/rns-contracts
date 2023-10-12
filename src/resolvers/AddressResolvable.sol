// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@rns-contracts/interfaces/resolvers/IAddressResolver.sol";
import "./BaseVersion.sol";

abstract contract AddressResolvable is IAddressResolver, ERC165, BaseVersion {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from version => node => address
  mapping(uint64 version => mapping(bytes32 node => address addr)) internal _versionAddress;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override(BaseVersion, ERC165) returns (bool) {
    return interfaceID == type(IAddressResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IAddressResolver
   */
  function addr(bytes32 node) public view virtual override returns (address payable) {
    return payable(_versionAddress[_recordVersion[node]][node]);
  }

  /**
   * @dev See {IAddressResolver-setAddr}.
   */
  function _setAddr(bytes32 node, address addr_) internal {
    emit AddrChanged(node, addr_);
    _versionAddress[_recordVersion[node]][node] = addr_;
  }
}
