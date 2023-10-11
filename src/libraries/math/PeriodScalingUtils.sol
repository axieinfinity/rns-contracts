//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import { PowMath } from "./PowMath.sol";

struct PeriodScaler {
  uint192 ratio;
  uint64 period;
}

library LibPeriodScaler {
  using PowMath for uint256;

  error PeriodNumOverflowedUint16(uint256 n);

  /// @dev The precision number of calculation is 2
  uint256 public constant MAX_PERCENTAGE = 100_00;

  /**
   * @dev Scales down the input value `v` for a percentage of `self.ratio` each period `self.period`.
   * Reverts if the passed period is larger than 2^16 - 1.
   *
   * @param self The period scaler with specific period and ratio
   * @param v The original value to scale based on the rule `self`
   * @param maxR The maximum value of 100%. Eg, if the `self.ratio` in range of [0;100_00] reflexes 0-100%, this param
   * must be 100_00
   * @param dur The passed duration in the same uint with `self.period`
   */
  function scaleDown(PeriodScaler memory self, uint256 v, uint64 maxR, uint256 dur) internal pure returns (uint256 rs) {
    uint256 n = dur / uint256(self.period);
    if (n == 0 || self.ratio == 0) return v;
    if (maxR == self.ratio) return 0;
    if (n > type(uint16).max) revert PeriodNumOverflowedUint16(n);

    unchecked {
      // Normalizes the input ratios to be in range of [0;MAX_PERCENTAGE]
      uint256 p = Math.mulDiv(maxR - self.ratio, MAX_PERCENTAGE, maxR);
      return v.mulDiv({ y: p, d: MAX_PERCENTAGE, n: uint16(n) });
    }
  }
}
