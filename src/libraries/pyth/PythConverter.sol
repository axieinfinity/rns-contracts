// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { PythStructs } from "@pythnetwork/PythStructs.sol";
import { PowMath } from "../math/PowMath.sol";

library PythConverter {
  error ErrExponentTooLarge(int32 expo);
  error ErrComputedPriceTooLarge(int32 expo1, int32 expo2, int64 price1);

  /**
   * @dev Multiples and converts the price into token wei with decimals `outDecimals`.
   */
  function mul(PythStructs.Price memory self, uint256 inpWei, int32 inpDecimals, int32 outDecimals)
    internal
    pure
    returns (uint256 outWei)
  {
    return Math.mulDiv(
      inpWei, PowMath.exp10(uint256(int256(self.price)), outDecimals + self.expo), PowMath.exp10(1, inpDecimals)
    );
  }

  /**
   * @dev Inverses token price of tokenA/tokenB to tokenB/tokenA.
   */
  function inverse(PythStructs.Price memory self, int32 expo) internal pure returns (PythStructs.Price memory outPrice) {
    uint256 exp10p1 = PowMath.exp10(1, -self.expo);
    if (exp10p1 > uint256(type(int256).max)) revert ErrExponentTooLarge(self.expo);
    uint256 exp10p2 = PowMath.exp10(1, -expo);
    if (exp10p2 > uint256(type(int256).max)) revert ErrExponentTooLarge(expo);
    int256 price = (int256(exp10p1) * int256(exp10p2)) / self.price;
    if (price > type(int64).max) revert ErrComputedPriceTooLarge(self.expo, expo, self.price);

    return PythStructs.Price({ price: int64(price), conf: self.conf, expo: expo, publishTime: self.publishTime });
  }
}
