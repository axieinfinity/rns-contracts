// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { console2, Test } from "forge-std/Test.sol";
import { RNSCommission } from "@rns-contracts/RNSCommission.sol";
import { INSCommission } from "@rns-contracts/interfaces/INSCommission.sol";

contract RNSCommissionTest is Test {
  event CommissionsUpdated(address indexed updatedBy, INSCommission.Commission[] commissionInfos);

  event CommissionInfoUpdated(
    address indexed updatedBy, uint256 indexed commissionIdx, address payable newRecipient, string newName
  );

  RNSCommission internal _rnsCommission;
  address internal _admin;
  address internal _proxyAdmin;
  address[] internal _senders;
  address payable internal _skyMavisTreasuryAddr;
  address payable internal _roninNetworkTreasuryAddr;
  string[] internal _names;
  uint256 internal _skyMavisRatio;
  uint256 internal _roninRatio;
  INSCommission.Commission[] internal _treasuryCommission;

  mapping(bytes4 errorCode => string indentifier) internal _errorIndentifier;

  function setUp() public {
    _admin = makeAddr("admin");
    _proxyAdmin = makeAddr("proxyAdmin");
    _names = new string[](2);

    _senders = new address[](1);
    _senders[0] = makeAddr("RNS");

    _skyMavisTreasuryAddr = payable(makeAddr("skyMavis"));
    _roninNetworkTreasuryAddr = payable(makeAddr("ronin"));

    _skyMavisRatio = 70_00;
    _roninRatio = 30_00;

    _names[0] = "Sky Mavis";
    _names[1] = "RONIN";
    INSCommission.Commission[] memory treasuryCommission = new INSCommission.Commission[](2);

    treasuryCommission[0] =
      INSCommission.Commission({ recipient: _skyMavisTreasuryAddr, ratio: _skyMavisRatio, name: _names[0] });
    treasuryCommission[1] =
      INSCommission.Commission({ recipient: _roninNetworkTreasuryAddr, ratio: _roninRatio, name: _names[1] });

    _errorIndentifier[INSCommission.InvalidAmountOfRON.selector] = "InvalidAmountOfRON";
    _errorIndentifier[INSCommission.InvalidArrayLength.selector] = "InvalidArrayLength";
    _errorIndentifier[INSCommission.InvalidRatio.selector] = "InvalidRatio";

    address payable logic = payable(address(new RNSCommission()));

    _rnsCommission = RNSCommission(
      payable(
        address(
          new TransparentUpgradeableProxy(
            logic, _proxyAdmin, abi.encodeCall(RNSCommission.initialize, (_admin, treasuryCommission, _senders))
          )
        )
      )
    );
  }

  function _setCommissions(INSCommission.Commission[] memory commissionInfos) internal {
    _rnsCommission.setCommissions(commissionInfos);
  }

  function _createCommissionInfo(
    address payable[] memory treasuriesAddress,
    uint256[] memory ratio,
    string[] memory names
  ) internal returns (INSCommission.Commission[] memory commissionInfo) {
    require(treasuriesAddress.length == ratio.length, "Invalid Length");

    uint256 length = treasuriesAddress.length;
    commissionInfo = new INSCommission.Commission[](length);

    for (uint256 i = 0; i < length; ++i) {
      commissionInfo[i] =
        INSCommission.Commission({ recipient: treasuriesAddress[i], ratio: ratio[i], name: _names[i] });
    }
  }

  function test_getCommissions() external {
    RNSCommission.Commission[] memory commissionInfo = _rnsCommission.getCommissions();
    assert(commissionInfo.length == 2);
  }
}
