// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { console2 } from "forge-std/console2.sol";
import { RNSDeploy } from "script/RNSDeploy.s.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import { OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";
import { OwnedMulticaller } from "@rns-contracts/utils/OwnedMulticaller.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";

contract Migration__20231106_TransferOwnership is RNSDeploy {
  function _injectDependencies() internal virtual override {
    _setDependencyDeployScript(ContractKey.OwnedMulticaller, new OwnedMulticallerDeploy());
  }

  function run() public trySetUp {
    // fill in original owner
    address originalOwner = _config.getSender();

    RNSUnified rns = RNSUnified(_config.getAddressFromCurrentNetwork(ContractKey.RNSUnified));
    OwnedMulticaller multicall = OwnedMulticaller(loadContractOrDeploy(ContractKey.OwnedMulticaller));
    address auction = _config.getAddressFromCurrentNetwork(ContractKey.RNSAuction);
    address ronController = _config.getAddressFromCurrentNetwork(ContractKey.RONRegistrarController);
    address reverseRegistrar = _config.getAddressFromCurrentNetwork(ContractKey.RNSReverseRegistrar);

    uint256 reverseId = uint256(LibRNSDomain.namehash("reverse"));
    console2.log("reverseId", reverseId);
    uint256 addrReverseId = uint256(LibRNSDomain.namehash("addr.reverse"));
    console2.log("reverse.addr id", addrReverseId);

    address currentOwner = rns.ownerOf(LibRNSDomain.RON_ID);
    assertEq(currentOwner, rns.ownerOf(reverseId), "currentOwner != rns.ownerOf(reverseId)");
    assertEq(currentOwner, rns.ownerOf(addrReverseId), "currentOwner != rns.ownerOf(addrReverseId)");

    if (!rns.isApprovedForAll(currentOwner, address(multicall))) {
      // approve for owned-multicall contract
      vm.broadcast(currentOwner);
      vm.resumeGasMetering();
      rns.setApprovalForAll(address(multicall), true);
      vm.pauseGasMetering();
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
    vm.resumeGasMetering();
    multicall.multicall(targets, callDatas, values);
    vm.pauseGasMetering();

    vm.startBroadcast(originalOwner);
    vm.resumeGasMetering();
    rns.setApprovalForAll(address(auction), true);
    rns.setApprovalForAll(address(ronController), true);
    rns.approve(address(reverseRegistrar), addrReverseId);
    vm.stopBroadcast();
    vm.pauseGasMetering();

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
