// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INSUnified } from "../interfaces/INSUnified.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";

contract OwnedMulticaller is Ownable {
  using ErrorHandler for bool;

  constructor(address owner_) {
    require(owner_ != address(0), "owner_ == address(0x0)");
    _transferOwnership(owner_);
  }

  function kill() external onlyOwner {
    selfdestruct(payable(_msgSender()));
  }

  function multiMint(
    INSUnified rns,
    uint256 parentId,
    address resolver,
    uint64 duration,
    address[] calldata tos,
    string[] calldata labels
  ) external onlyOwner {
    for (uint256 i; i < labels.length; ++i) {
      rns.mint(parentId, labels[i], resolver, tos[i], duration);
    }
  }

  function multicall(address[] calldata tos, bytes[] calldata callDatas, uint256[] calldata values)
    external
    payable
    onlyOwner
    returns (bool[] memory results, bytes[] memory returnDatas)
  {
    require(tos.length == callDatas.length && tos.length == values.length, "invalid length");
    results = new bool[](tos.length);
    returnDatas = new bytes[](tos.length);

    for (uint256 i; i < tos.length; ++i) {
      (results[i], returnDatas[i]) = tos[i].call{ value: values[i] }(callDatas[i]);
      results[i].handleRevert(returnDatas[i]);
    }
  }
}
