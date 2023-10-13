// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { INSUnified } from "@rns-contracts/interfaces/INSUnified.sol";
import { INSReverseRegistrar } from "@rns-contracts/interfaces/INSReverseRegistrar.sol";
import { IABIResolver } from "./IABIResolver.sol";
import { IAddressResolver } from "./IAddressResolver.sol";
import { IContentHashResolver } from "./IContentHashResolver.sol";
import { IDNSRecordResolver } from "./IDNSRecordResolver.sol";
import { IDNSZoneResolver } from "./IDNSZoneResolver.sol";
import { IInterfaceResolver } from "./IInterfaceResolver.sol";
import { INameResolver } from "./INameResolver.sol";
import { IPublicKeyResolver } from "./IPublicKeyResolver.sol";
import { ITextResolver } from "./ITextResolver.sol";
import { IMulticallable } from "../IMulticallable.sol";

interface IPublicResolver is
  IABIResolver,
  IAddressResolver,
  IContentHashResolver,
  IDNSRecordResolver,
  IDNSZoneResolver,
  IInterfaceResolver,
  INameResolver,
  IPublicKeyResolver,
  ITextResolver,
  IMulticallable
{
  /// @dev See {IERC1155-ApprovalForAll}. Logged when an operator is added or removed.
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /// @dev Logged when a delegate is approved or an approval is revoked.
  event Approved(address owner, bytes32 indexed node, address indexed delegate, bool indexed approved);

  /**
   * @dev Checks if an account is authorized to manage the resolution of a specific RNS node.
   * @param node The RNS node.
   * @param account The account address being checked for authorization.
   * @return A boolean indicating whether the account is authorized.
   */
  function isAuthorized(bytes32 node, address account) external view returns (bool);

  /**
   * @dev Retrieves the RNSUnified associated with this resolver.
   */
  function getRNSUnified() external view returns (INSUnified);

  /**
   * @dev Retrieves the reverse registrar associated with this resolver.
   */
  function getReverseRegistrar() external view returns (INSReverseRegistrar);

  /**
   * @dev This function provides an extra security check when called from privileged contracts (such as
   * RONRegistrarController) that can set records on behalf of the node owners.
   *
   * Reverts if the node is not null but calldata is mismatched.
   */
  function multicallWithNodeCheck(bytes32 node, bytes[] calldata data) external returns (bytes[] memory results);
}
