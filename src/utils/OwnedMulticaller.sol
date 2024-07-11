// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INSUnified } from "../interfaces/INSUnified.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";

contract OwnedMulticaller is Ownable {
  using ErrorHandler for bool;

  constructor(address owner_) {
    require(owner_ != address(0), "OwnedMulticaller: owner_ is null");
    _transferOwnership(owner_);
  }

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
}
