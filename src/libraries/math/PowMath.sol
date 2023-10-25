//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library PowMath {
  using Math for uint256;
  using SafeMath for uint256;

  /**
   * @dev Negative exponent n for x*10^n.
   */
  function exp10(uint256 x, int32 n) internal pure returns (uint256) {
    if (n < 0) {
      return x / 10 ** uint32(-n);
    } else if (n > 0) {
      return x * 10 ** uint32(n);
    } else {
      return x;
    }
  }

  /**
   * @dev Calculates floor(x * (y / d)**n) with full precision.
   */
  function mulDiv(uint256 x, uint256 y, uint256 d, uint16 n) internal pure returns (uint256 r) {
    unchecked {
      if (y == d || n == 0) return x;
      r = x;

      bool ok;
      uint256 r_;
      uint16 nd_;

      {
        uint16 ye = uint16(Math.min(n, findMaxExponent(y)));
        while (ye > 0) {
          (ok, r_) = r.tryMul(y ** ye);
          if (ok) {
            r = r_;
            n -= ye;
            nd_ += ye;
          }
          ye = uint16(Math.min(ye / 2, n));
        }
      }

      while (n > 0) {
        (ok, r_) = r.tryMul(y);
        if (ok) {
          r = r_;
          n--;
          nd_++;
        } else if (nd_ > 0) {
          r /= d;
          nd_--;
        } else {
          r = r.mulDiv(y, d);
          n--;
        }
      }

      uint16 de = findMaxExponent(d);
      while (nd_ > 0) {
        uint16 e = uint16(Math.min(de, nd_));
        r /= d ** e;
        nd_ -= e;
      }
    }
  }

  /**
   * @dev Calculates floor(x * (y / d)**n) with low precision.
   */
  function mulDivLowPrecision(uint256 x, uint256 y, uint256 d, uint16 n) internal pure returns (uint256) {
    return uncheckedMulDiv(x, y, d, n, findMaxExponent(Math.max(y, d)));
  }

  /**
   * @dev Aggregated calculate multiplications.
   * ```
   * r = x*(y/d)^k
   *   = \prod(x*(y/d)^{k_i}) \ where \ sum(k_i) = k
   * ```
   */
  function uncheckedMulDiv(uint256 x, uint256 y, uint256 d, uint16 n, uint16 maxE) internal pure returns (uint256 r) {
    unchecked {
      r = x;
      uint16 e;
      while (n > 0) {
        e = uint16(Math.min(n, maxE));
        r = r.mulDiv(y ** e, d ** e);
        n -= e;
      }
    }
  }

  /**
   * @dev Returns the largest exponent `k` where, x^k <= 2^256-1
   * Note: n = Surd[2^256-1,k]
   *         = 10^( log2(2^256-1) / k * log10(2) )
   */
  function findMaxExponent(uint256 x) internal pure returns (uint16 k) {
    if (x < 3) k = 255;
    else if (x < 4) k = 128;
    else if (x < 16) k = 64;
    else if (x < 256) k = 32;
    else if (x < 7132) k = 20;
    else if (x < 11376) k = 19;
    else if (x < 19113) k = 18;
    else if (x < 34132) k = 17;
    else if (x < 65536) k = 16;
    else if (x < 137271) k = 15;
    else if (x < 319558) k = 14;
    else if (x < 847180) k = 13;
    else if (x < 2642246) k = 12;
    else if (x < 10134189) k = 11;
    else if (x < 50859009) k = 10;
    else if (x < 365284285) k = 9;
    else if (x < 4294967296) k = 8;
    else if (x < 102116749983) k = 7;
    else if (x < 6981463658332) k = 6;
    else if (x < 2586638741762875) k = 5;
    else if (x < 18446744073709551616) k = 4;
    else if (x < 48740834812604276470692695) k = 3;
    else if (x < 340282366920938463463374607431768211456) k = 2;
    else k = 1;
  }
}
