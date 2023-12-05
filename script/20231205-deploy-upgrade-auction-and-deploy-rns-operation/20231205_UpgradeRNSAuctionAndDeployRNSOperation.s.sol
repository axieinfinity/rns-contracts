// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ContractKey } from "foundry-deployment-kit/configs/ContractConfig.sol";
import { Network, Config__Mainnet20231205 } from "script/20231205-deploy-upgrade-auction-and-deploy-rns-operation/20231205_MainnetConfig.s.sol";
import { Migration__20231123_UpgradeAuctionClaimeUnbiddedNames as UpgradeAuctionScript } from "script/20231123-upgrade-auction-claim-unbidded-names/20231123_UpgradeAuctionClaimUnbiddedNames.s.sol";
import { RNSOperation, Migration__20231124_DeployRNSOperation as DeployRNSOperationScript  } from "script/20231124-deploy-rns-operation/20231124_DeployRNSOperation.s.sol";

contract Migration__20231205_UpgradeRNSAuctionAndDeployRNSOperation is Config__Mainnet20231205 {
  function run() public trySetUp onMainnet {
    Config memory config = getConfig();

    // upgrade rns auction contract
    new UpgradeAuctionScript().run();
    // deploy rns operation contract
    new DeployRNSOperationScript().run();

    RNSOperation rnsOperation = RNSOperation(_config.getAddressFromCurrentNetwork(ContractKey.RNSOperation));

    // transfer owner ship for RNSOperation
    vm.broadcast(rnsOperation.owner());
    rnsOperation.transferOwnership(config.rnsOperationOwner);

    assertTrue(rnsOperation.owner() == config.rnsOperationOwner);
  }
}
