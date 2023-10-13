// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ErrorHandler {
  error ExternalCallFailed();

  function handleRevert(bool status, bytes memory returnOrRevertData) internal pure {
    assembly {
      if iszero(status) {
        let revertLength := mload(returnOrRevertData)
        if iszero(iszero(revertLength)) {
          // Start of revert data bytes. The 0x20 offset is always the same.
          revert(add(returnOrRevertData, 0x20), revertLength)
        }

        //  revert ExternalCallFailed()
        mstore(0x00, 0x350c20f1)
        revert(0x1c, 0x04)
      }
    }
  }
}
