// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract OwnedMulticaller is Ownable, IERC721Receiver, IERC1155Receiver {
  using ErrorHandler for bool;

  constructor(address owner_) {
    require(owner_ != address(0), "OwnedMulticaller: owner_ is null");

    _transferOwnership(owner_);
  }

  /**
   * @dev Execute multiple calls in a single transaction.
   * @param tos The addresses to call.
   * @param callDatas The call data for each call.
   * @param values The value to send for each call.
   * @return results The results of each call.
   * @return returnDatas The return data of each call.
   */
  function multicall(address[] calldata tos, bytes[] calldata callDatas, uint256[] calldata values)
    external
    payable
    onlyOwner
    returns (bool[] memory results, bytes[] memory returnDatas)
  {
    uint256 length = tos.length;
    require(length == callDatas.length && length == values.length, "OwnedMulticaller: mismatch length");
    results = new bool[](length);
    returnDatas = new bytes[](length);

    for (uint256 i; i < length; ++i) {
      (results[i], returnDatas[i]) = tos[i].call{ value: values[i] }(callDatas[i]);
      results[i].handleRevert(returnDatas[i]);
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId
      || interfaceId == type(IERC1155Receiver).interfaceId;
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    return msg.sig;
  }

  /**
   * @dev See {IERC1155Receiver-onERC1155Received}.
   */
  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    external
    pure
    returns (bytes4)
  {
    return msg.sig;
  }

  /**
   * @dev See {IERC1155Receiver-onERC1155Received}.
   */
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
    return msg.sig;
  }
}
