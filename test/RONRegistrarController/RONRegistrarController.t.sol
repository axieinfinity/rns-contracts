// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console2, Test } from "forge-std/Test.sol";
import { RNSUnified } from "@rns-contracts/RNSUnified.sol";
import {
  RONRegistrarController,
  INSUnified,
  INameChecker,
  INSDomainPrice,
  INSReverseRegistrar
} from "@rns-contracts/RONRegistrarController.sol";
import { RONTransferHelper } from "@rns-contracts/libraries/transfers/RONTransferHelper.sol";
import { LibString } from "@rns-contracts/libraries/LibString.sol";
import { LibRNSDomain } from "@rns-contracts/libraries/LibRNSDomain.sol";
import { RNSUnifiedDeploy } from "script/contracts/RNSUnifiedDeploy.s.sol";

contract RONRegistrarControllerTest is Test {
  using LibString for string;
  using LibRNSDomain for string;

  address internal _caller;
  address internal _admin;
  address internal _pauser;
  address internal _proxyAdmin;
  address payable internal _treasury;
  uint256 internal _maxCommitmentAge;
  uint256 internal _minCommitmentAge;
  uint256 internal _minRegistrationDuration;
  INSUnified internal _rnsUnified;
  INameChecker internal _nameChecker;
  INSDomainPrice internal _priceOracle;
  INSReverseRegistrar internal _reverseRegistrar;

  RONRegistrarController internal _controller;

  function setUp() external {
    vm.warp(block.timestamp + 10 days);
    _caller = makeAddr("caller");
    _admin = makeAddr("admin");
    _pauser = makeAddr("pauser");
    _proxyAdmin = makeAddr("proxyAdmin");
    _treasury = payable(makeAddr("treasury"));
    _maxCommitmentAge = 1 days;
    _minCommitmentAge = 10 seconds;
    _minRegistrationDuration = 1 days;
    _rnsUnified = INSUnified(address(new RNSUnifiedDeploy().run()));
    _nameChecker = INameChecker(makeAddr("nameChecker"));
    _priceOracle = INSDomainPrice(address(new PriceOracleMock()));
    _reverseRegistrar = INSReverseRegistrar(makeAddr("reverseRegistrar"));
    vm.deal(_caller, 100 ether);

    address logic = address(new RONRegistrarController());
    _controller = RONRegistrarController(
      address(
        new TransparentUpgradeableProxy(
          logic,
          _proxyAdmin,
          abi.encodeCall(
            RONRegistrarController.initialize,
            (
              _admin,
              _pauser,
              _treasury,
              _maxCommitmentAge,
              _minCommitmentAge,
              _minRegistrationDuration,
              _rnsUnified,
              _nameChecker,
              _priceOracle,
              _reverseRegistrar
            )
          )
        )
      )
    );

    RNSUnified _rns = RNSUnified(address(_rnsUnified));
    address admin = _rns.getRoleMember(_rns.DEFAULT_ADMIN_ROLE(), 0);
    bytes32 controllerRole = _rns.CONTROLLER_ROLE();
    vm.prank(admin);
    _rns.grantRole(controllerRole, address(_controller));
  }
}

contract PriceOracleMock {
  function getRenewalFee(string calldata label, uint256 duration)
    external
    view
    returns (INSDomainPrice.UnitPrice memory basePrice, INSDomainPrice.UnitPrice memory tax)
  {
    basePrice = INSDomainPrice.UnitPrice({ usd: 1.5 ether, ron: 1 ether });
    tax = INSDomainPrice.UnitPrice({ usd: 0.15 ether, ron: 0.1 ether });
  }
}
