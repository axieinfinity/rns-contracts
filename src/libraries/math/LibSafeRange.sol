//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibSafeRange {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    unchecked {
      c = a + b;
      if (c < a) return type(uint256).max;
    }
  }

  /**
   * @dev Returns value of a + b; in case result is larger than upperbound, upperbound is returned.
   */
  function addWithUpperbound(uint256 a, uint256 b, uint256 ceil) internal pure returns (uint256 c) {
    if (a > ceil || b > ceil) return ceil;
    c = add(a, b);
    if (c > ceil) return ceil;
  }
}
