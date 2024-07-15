// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Contract } from "script/utils/Contract.sol";
import { Migration } from "script/Migration.s.sol";
import { DefaultNetwork } from "@fdk/utils/DefaultNetwork.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { OwnedMulticaller, OwnedMulticallerDeploy } from "script/contracts/OwnedMulticallerDeploy.s.sol";
import { INSDomainPrice } from "src/interfaces/INSDomainPrice.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract Migration__01_DeployNew_OwnedMulticaller is Migration {
  address internal constant TUDO = 0x0Ebf93387093D7b7cDa9a4dE5d558507810af5eD; // TuDo's trezor

  OwnedMulticaller _multicaller;
  address internal _rns;
  address internal _auction;
  address internal _nameChecker;
  address internal _domainPrice;
  address internal _publicResolver;
  address internal _reverseRegistrar;
  address internal _ronController;

  function run() external onlyOn(DefaultNetwork.RoninMainnet.key()) {
    _rns = loadContract(Contract.RNSUnified.key());
    _auction = loadContract(Contract.RNSAuction.key());
    _nameChecker = loadContract(Contract.NameChecker.key());
    _domainPrice = loadContract(Contract.RNSDomainPrice.key());
    _publicResolver = loadContract(Contract.PublicResolver.key());
    _reverseRegistrar = loadContract(Contract.RNSReverseRegistrar.key());
    _ronController = loadContract(Contract.RONRegistrarController.key());
    _multicaller = OwnedMulticaller(new OwnedMulticallerDeploy().overrideArgs(abi.encode(TUDO)).run());

    vm.startBroadcast(TUDO);

    address[] memory tos = new address[](4);
    bytes[] memory callDatas = new bytes[](4);
    uint256[] memory values = new uint256[](4);

    tos[0] = address(_rns);
    tos[1] = address(_rns);
    tos[2] = address(_rns);
    tos[3] = address(_rns);

    callDatas[0] = abi.encodeCall(ERC721.setApprovalForAll, (address(_auction), true));
    callDatas[1] = abi.encodeCall(ERC721.setApprovalForAll, (address(_ronController), true));
    callDatas[2] = abi.encodeCall(ERC721.setApprovalForAll, (address(_reverseRegistrar), true));
    // Grant approval for RNSOperation contract.
    // Verify: https://app.roninchain.com/address/0xCD245263eDdEE593a5A66f93f74C58c544957339
    callDatas[3] = abi.encodeCall(ERC721.setApprovalForAll, (0xCD245263eDdEE593a5A66f93f74C58c544957339, true));

    _multicaller.multicall(tos, callDatas, values);

    vm.stopBroadcast();
  }

  function _postCheck() internal virtual override {
    assertEq(_multicaller.owner(), TUDO);
  }
}
