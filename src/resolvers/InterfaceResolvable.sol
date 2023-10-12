// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { BaseVersion } from "./BaseVersion.sol";
import { IInterfaceResolver } from "@rns-contracts/interfaces/resolvers/IInterfaceResolver.sol";

abstract contract InterfaceResolvable is IInterfaceResolver, ERC165, BaseVersion {
  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  /// @dev Mapping from version => node => interfaceID => address
  mapping(uint64 version => mapping(bytes32 node => mapping(bytes4 interfaceID => address addr))) internal
    _versionInterface;

  /**
   * @dev Override {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceID) public view virtual override(BaseVersion, ERC165) returns (bool) {
    return interfaceID == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceID);
  }

  /**
   * @inheritdoc IInterfaceResolver
   */
  function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view virtual override returns (address) {
    address implementer = _versionInterface[_recordVersion[node]][node][interfaceID];
    if (implementer != address(0)) return implementer;

    address addrOfNode = addr(node);
    if (addrOfNode == address(0)) return address(0);

    bool success;
    bytes memory returnData;

    (success, returnData) =
      addrOfNode.staticcall(abi.encodeCall(IERC165.supportsInterface, (type(IERC165).interfaceId)));

    // EIP 165 not supported by target
    if (!_isValidReturnData(success, returnData)) return address(0);

    (success, returnData) = addrOfNode.staticcall(abi.encodeCall(IERC165.supportsInterface, (interfaceID)));
    // Specified interface not supported by target
    if (!_isValidReturnData(success, returnData)) return address(0);

    return addrOfNode;
  }

  /**
   * @dev See {IAddressResolver-addr}.
   */
  function addr(bytes32 node) public view virtual returns (address payable);

  /**
   * @dev Checks whether the return data is valid.
   */
  function _isValidReturnData(bool success, bytes memory returnData) internal pure returns (bool) {
    return success || returnData.length < 32 || returnData[31] == 0;
  }

  /**
   * @dev See {InterfaceResolver-setInterface}.
   */
  function _setInterface(bytes32 node, bytes4 interfaceID, address implementer) internal virtual {
    _versionInterface[_recordVersion[node]][node][interfaceID] = implementer;
    emit InterfaceChanged(node, interfaceID, implementer);
  }
}
