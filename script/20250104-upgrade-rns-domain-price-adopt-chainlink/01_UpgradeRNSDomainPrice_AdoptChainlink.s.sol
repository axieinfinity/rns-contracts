// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { RNSDomainPrice } from "src/RNSDomainPrice.sol";
import { ISharedArgument } from "script/interfaces/ISharedArgument.sol";
import { IRONRegistrarController } from "src/interfaces/IRONRegistrarController.sol";
import { Migration } from "script/Migration.s.sol";

contract Migration__20250401_UpgradeDomainPrice_AdoptChainlink is Migration {
  uint256 _usdPricePyth;
  uint256 _ronPricePyth;

  function _preCheck() internal virtual override {
    (_usdPricePyth, _ronPricePyth) =
      IRONRegistrarController(loadContract(Contract.RONRegistrarController.key())).rentPrice("tudo-hihi-haha", 365 days);
  }

  function _postCheck() internal virtual override {
    (uint256 usdPriceChainlink, uint256 ronPriceChainlink) =
      IRONRegistrarController(loadContract(Contract.RONRegistrarController.key())).rentPrice("tudo-hihi-haha", 365 days);

    assertApproxEqRel(usdPriceChainlink, _usdPricePyth, 1e16, "USD price mismatch");
    assertApproxEqRel(ronPriceChainlink, _ronPricePyth, 1e16, "RON price mismatch");

    super._postCheck();
  }

  function run() public {
    ISharedArgument.RNSDomainPriceParam memory param = config.sharedArguments().rnsDomainPrice;
    _upgradeProxy(
      Contract.RNSDomainPrice.key(),
      abi.encodeCall(RNSDomainPrice.initializeV2, (param.aggregator, param.maxAcceptableAge))
    );
  }
}
