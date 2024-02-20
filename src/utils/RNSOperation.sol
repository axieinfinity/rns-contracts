// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { INSUnified } from "../interfaces/INSUnified.sol";
import { INSAuction } from "../interfaces/INSAuction.sol";
import { INSDomainPrice } from "../interfaces/INSDomainPrice.sol";
import { LibRNSDomain } from "../libraries/LibRNSDomain.sol";

contract RNSOperation is Ownable {
  INSUnified public immutable rns;
  address public immutable resolver;
  INSAuction public immutable auction;
  INSDomainPrice public immutable domainPrice;

  constructor(INSUnified rns_, address resolver_, INSAuction auction_, INSDomainPrice domainPrice_) {
    rns = rns_;
    auction = auction_;
    resolver = resolver_;
    domainPrice = domainPrice_;
  }

  /**
   * @dev Allows the owner to mint RNS domains in bulk with specified labels and durations.
   * @param tos The array of addresses to receive the minted domains.
   * @param labels The array of labels for the minted domains.
   * @param duration The duration for which the domains will be owned.
   */
  function bulkMint(address[] calldata tos, string[] calldata labels, uint64 duration) external onlyOwner {
    require(labels.length == tos.length, "RNSOperation: length mismatch");

    for (uint256 i; i < labels.length; ++i) {
      rns.mint(LibRNSDomain.RON_ID, labels[i], resolver, tos[i], duration);
    }
  }

  /**
   * @dev Allows the owner to set the protection status of multiple RNS domains in bulk.
   * @param labels The array of labels for the domains.
   * @param shouldProtect A boolean indicating whether to protect or unprotect the specified domains.
   */
  function bulkSetProtected(string[] calldata labels, bool shouldProtect) external onlyOwner {
    rns.bulkSetProtected(toIds(labels), shouldProtect);
  }

  /**
   * @dev Allows the owner to bulk override the renewal fees for specified RNS domains.
   * @param labels The array of labels for the RNS domains.
   * @param yearlyUSDPrices The array of yearly renewal fees in USD (no decimals) for the corresponding RNS domains.
   * @dev The `yearlyUSDPrices` array should represent the yearly renewal fees in USD for each domain.
   */
  function bulkOverrideRenewalFees(string[] calldata labels, uint256[] calldata yearlyUSDPrices) external onlyOwner {
    require(labels.length == yearlyUSDPrices.length, "RNSOperation: length mismatch");

    bytes32[] memory lbHashes = new bytes32[](labels.length);
    for (uint256 i; i < lbHashes.length; ++i) {
      lbHashes[i] = LibRNSDomain.hashLabel(labels[i]);
    }
    uint256[] memory usdPrices = new uint256[](yearlyUSDPrices.length);
    for (uint256 i; i < usdPrices.length; ++i) {
      usdPrices[i] = Math.mulDiv(yearlyUSDPrices[i], 1 ether, 365 days);
    }

    domainPrice.bulkOverrideRenewalFees(lbHashes, usdPrices);
  }

  /**
   * @dev Allows the owner to bulk override the tiers for specified RNS domains.
   * @param labels The array of labels for the RNS domains.
   * @param tiers The array of tiers for the corresponding RNS domains.
   * @dev The `tiers` array should represent the tiers for each domain.
   */
  function bulkOverrideTiers(string[] calldata labels, uint256[] calldata tiers) external onlyOwner {
    require(labels.length == tiers.length, "RNSOperation: length mismatch");

    bytes32[] memory lbHashes = new bytes32[](labels.length);
    for (uint256 i; i < lbHashes.length; ++i) {
      lbHashes[i] = LibRNSDomain.hashLabel(labels[i]);
    }

    domainPrice.bulkOverrideTiers(lbHashes, tiers);
  }

  /**
   * @dev Allows the owner to reclaim unbidded RNS domain names and transfer them to specified addresses.
   * @param tos The array of addresses to which the unbidded domains will be transferred.
   * @param labels The array of labels for the unbidded domains to be reclaimed.
   * @param allowFailure Flag to indicate whether to allow failure if a domain is already being bid on.
   */
  function reclaimUnbiddedNames(address[] calldata tos, string[] calldata labels, bool allowFailure) external onlyOwner {
    auction.bulkClaimUnbiddedNames(tos, toIds(labels), allowFailure);
  }

  /**
   * @dev Converts an array of labels to an array of corresponding RNS domain IDs.
   * @param labels The array of labels to be converted to IDs.
   * @return ids The array of RNS domain IDs.
   */
  function toIds(string[] calldata labels) public pure returns (uint256[] memory ids) {
    ids = new uint256[](labels.length);

    for (uint256 i; i < labels.length; ++i) {
      ids[i] = LibRNSDomain.toId(LibRNSDomain.RON_ID, labels[i]);
    }
  }
}
