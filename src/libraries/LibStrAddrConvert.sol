//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibStrAddrConvert {
  error InvalidStringLength();
  error InvalidCharacter(bytes1 char);

  /// @dev Lookup constant for method. See more detail at https://eips.ethereum.org/EIPS/eip-181

  bytes32 private constant LOOKUP = 0x3031323334353637383961626364656600000000000000000000000000000000;

  /**
   * @dev Converts an address to string.
   */
  function toString(address addr) internal pure returns (string memory stringifiedAddr) {
    assembly ("memory-safe") {
      mstore(stringifiedAddr, 40)
      let ptr := add(stringifiedAddr, 0x20)
      for { let i := 40 } gt(i, 0) { } {
        i := sub(i, 1)
        mstore8(add(i, ptr), byte(and(addr, 0xf), LOOKUP))
        addr := div(addr, 0x10)

        i := sub(i, 1)
        mstore8(add(i, ptr), byte(and(addr, 0xf), LOOKUP))
        addr := div(addr, 0x10)
      }
    }
  }

  /**
   * @dev Converts string to address.
   * Reverts if the string length is not equal to 40.
   */
  function parseAddr(string memory stringifiedAddr) internal pure returns (address) {
    if (bytes(stringifiedAddr).length != 40) revert InvalidStringLength();
    uint160 addr;
    for (uint256 i = 0; i < 40; i += 2) {
      addr *= 0x100;
      addr += uint160(_hexCharToDec(bytes(stringifiedAddr)[i])) * 0x10;
      addr += _hexCharToDec(bytes(stringifiedAddr)[i + 1]);
    }
    return address(addr);
  }

  /**
   * @dev Converts a hex char (0-9, a-f, A-F) to decimal number.
   * Reverts if the char is invalid.
   */
  function _hexCharToDec(bytes1 c) private pure returns (uint8 r) {
    if ((bytes1("a") <= c) && (c <= bytes1("f"))) r = uint8(c) - 87;
    else if ((bytes1("A") <= c) && (c <= bytes1("F"))) r = uint8(c) - 55;
    else if ((bytes1("0") <= c) && (c <= bytes1("9"))) r = uint8(c) - 48;
    else revert InvalidCharacter(c);
  }
}
