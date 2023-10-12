// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title RONTransferHelper
 */
library RONTransferHelper {
  using Strings for *;

  /**
   * @dev Transfers RON and wraps result for the method caller to a recipient.
   */
  function safeTransfer(address payable _to, uint256 _value) internal {
    bool _success = send(_to, _value);
    if (!_success) {
      revert(
        string.concat("TransferHelper: could not transfer RON to ", _to.toHexString(), " value ", _value.toHexString())
      );
    }
  }

  /**
   * @dev Returns whether the call was success.
   * Note: this function should use with the `ReentrancyGuard`.
   */
  function send(address payable _to, uint256 _value) internal returns (bool _success) {
    (_success,) = _to.call{ value: _value }(new bytes(0));
  }
}
