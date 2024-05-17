// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Migration } from "script/Migration.s.sol";
import { Contract } from "script/utils/Contract.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { LibRNSDomain } from "src/libraries/LibRNSDomain.sol";
import { DefaultNetwork } from "foundry-deployment-kit/utils/DefaultNetwork.sol";

contract Migration__01_Revoke_Roles is Migration {
  address duke = 0x0F68eDBE14C8f68481771016d7E2871d6a35DE11;
  address multisig = 0x1FF1edE0242317b8C4229fC59E64DD93952019ef;

  function run() external onlyOn(DefaultNetwork.RoninMainnet.key()) {
    address[] memory contracts = new address[](5);
    contracts[0] = loadContract(Contract.RNSDomainPrice.key());
    contracts[1] = loadContract(Contract.RONRegistrarController.key());
    contracts[2] = loadContract(Contract.NameChecker.key());
    contracts[3] = loadContract(Contract.RNSUnified.key());
    contracts[4] = loadContract(Contract.RNSAuction.key());

    vm.startBroadcast(duke);

    Ownable(loadContract(Contract.OwnedMulticaller.key())).transferOwnership(multisig);
    Ownable(loadContract(Contract.RNSReverseRegistrar.key())).transferOwnership(multisig);
    // Transfer .ron domain ownership to multisig
    ERC721(loadContract(Contract.RNSUnified.key())).transferFrom(duke, multisig, LibRNSDomain.RON_ID);

    for (uint256 i; i < contracts.length; i++) {
      AccessControlEnumerable(contracts[i]).grantRole(0x0, multisig);

      assertTrue(
        AccessControlEnumerable(contracts[i]).getRoleMemberCount(0x0) > 0,
        string.concat("Role is empty", "contract: ", vm.toString(contracts[i]))
      );
    }

    vm.stopBroadcast();
  }
}
