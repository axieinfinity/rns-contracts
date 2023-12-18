// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Contract } from "script/utils/Contract.sol";
import { console2 as console } from "forge-std/console2.sol";
import { Migration } from "script/Migration.s.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";

contract Migration__20231106_TransferOwnership is Migration {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(Contract.OwnedMulticaller.key(), new OwnedMulticallerDeploy());
  }

  function run() public {
    // fill in original owner
    address originalOwner = config.getSender();

    RNSUnified rns = RNSUnified(config.getAddressFromCurrentNetwork(Contract.RNSUnified.key()));
    OwnedMulticaller multicall = OwnedMulticaller(loadContractOrDeploy(Contract.OwnedMulticaller.key()));
    address auction = config.getAddressFromCurrentNetwork(Contract.RNSAuction.key());
    address ronController = config.getAddressFromCurrentNetwork(Contract.RONRegistrarController.key());
    address reverseRegistrar = config.getAddressFromCurrentNetwork(Contract.RNSReverseRegistrar.key());

    uint256 reverseId = uint256(LibRNSDomain.namehash("reverse"));
    console.log("reverseId", reverseId);
    uint256 addrReverseId = uint256(LibRNSDomain.namehash("addr.reverse"));
    console.log("reverse.addr id", addrReverseId);

    address currentOwner = rns.ownerOf(LibRNSDomain.RON_ID);
    assertEq(currentOwner, rns.ownerOf(reverseId), "currentOwner != rns.ownerOf(reverseId)");
    assertEq(currentOwner, rns.ownerOf(addrReverseId), "currentOwner != rns.ownerOf(addrReverseId)");

    if (!rns.isApprovedForAll(currentOwner, address(multicall))) {
      // approve for owned-multicall contract
      vm.broadcast(currentOwner);
      rns.setApprovalForAll(address(multicall), true);
    }

    uint256[] memory values = new uint256[](3);
    address[] memory targets = new address[](3);
    targets[0] = targets[1] = targets[2] = address(rns);
    bytes[] memory callDatas = new bytes[](3);
    // transfer addr.reverse id to original owner
    callDatas[0] = abi.encodeCall(rns.transferFrom, (currentOwner, originalOwner, addrReverseId));
    // transfer .reverse id to original owner
    callDatas[1] = abi.encodeCall(rns.transferFrom, (currentOwner, originalOwner, reverseId));
    // transfer .ron id to original owner
    callDatas[2] = abi.encodeCall(rns.transferFrom, (currentOwner, originalOwner, LibRNSDomain.RON_ID));

    vm.broadcast(multicall.owner());
    multicall.multicall(targets, callDatas, values);

    vm.startBroadcast(originalOwner);

    rns.setApprovalForAll(address(auction), true);
    rns.setApprovalForAll(address(ronController), true);
    rns.approve(address(reverseRegistrar), addrReverseId);

    vm.stopBroadcast();

    assertTrue(
      rns.isApprovedForAll(originalOwner, address(auction)), "!rns.isApprovedForAll(originalOwner, address(auction))"
    );
    assertEq(
      rns.getApproved(addrReverseId),
      address(reverseRegistrar),
      "!rns.getApproved(addrReverseId), address(reverseRegistrar)"
    );
    assertTrue(
      rns.isApprovedForAll(originalOwner, address(ronController)),
      "!rns.isApprovedForAll(originalOwner, address(ronController))"
    );
  }
}
