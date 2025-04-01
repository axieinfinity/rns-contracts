// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { RONRegistrarController } from "@rns-contracts/RONRegistrarController.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { console2 } from "forge-std/console2.sol";

contract Migration__20231104_UpgradeController_Mainnet is Migration {
  RONRegistrarController internal _controller;
  RNSUnified internal _rns;

  struct MintParam {
    address owner;
    string name;
    address resolver;
    uint64 duration;
  }

  function run() public {
    _controller = RONRegistrarController(_upgradeProxy(Contract.RONRegistrarController.key()));
  }

  function _postCheck() internal override {
    _validateBulkRenew();
  }

  function _validateBulkRenew() internal logFn("_validateBulkRenew") {
    _rns = RNSUnified(loadContract(Contract.RNSUnified.key()));
    string[] memory names = new string[](2);
    uint64[] memory durations = new uint64[](2);
    address resolver = makeAddr("resolver");
    address owner = makeAddr("owner");
    names[0] = "minhtri0901";
    names[1] = "minhtri09012";
    durations[0] = 365 days;
    durations[1] = 365 days;
    MintParam[] memory mintParams = new MintParam[](2);
    mintParams[0] = MintParam({ owner: owner, name: names[0], resolver: resolver, duration: 0 });
    mintParams[1] = MintParam({ owner: owner, name: names[1], resolver: resolver, duration: 0 });

    uint256 ronId = 0xba69923fa107dbf5a25a073a10b7c9216ae39fbadc95dc891d460d9ae315d688;
    _mint(ronId, mintParams[0]);
    _mint(ronId, mintParams[1]);

    (, uint256 rentPrice1) = _controller.rentPrice(names[0], durations[0]);
    (, uint256 rentPrice2) = _controller.rentPrice(names[1], durations[1]);

    vm.deal(owner, 10 ether);
    vm.prank(owner);
    _controller.bulkRenew{ value: 10 ether }(names, durations);

    assertEq(owner.balance, 10 ether - rentPrice1 - rentPrice2);
    assertEq(_rns.getRecord(_controller.computeId(names[0])).mut.expiry, block.timestamp + durations[0]);
    assertEq(_rns.getRecord(_controller.computeId(names[1])).mut.expiry, block.timestamp + durations[1]);
    assertEq(_rns.getRecord(_controller.computeId(names[0])).mut.owner, owner);
    assertEq(_rns.getRecord(_controller.computeId(names[1])).mut.owner, owner);
    assertEq(_rns.getRecord(_controller.computeId(names[0])).immut.label, names[0]);
    assertEq(_rns.getRecord(_controller.computeId(names[1])).immut.label, names[1]);
  }

  function _mint(uint256 parentId, MintParam memory mintParam) internal returns (uint64 expiry, uint256 id) {
    vm.prank(address(_controller));
    (expiry, id) = _rns.mint(parentId, mintParam.name, mintParam.resolver, mintParam.owner, mintParam.duration);
  }
}
