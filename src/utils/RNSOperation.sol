// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INSUnified } from "../interfaces/INSUnified.sol";
import { INSAuction } from "../interfaces/INSAuction.sol";
import { LibRNSDomain } from "../libraries/LibRNSDomain.sol";

contract RNSOperation is Ownable {
  INSUnified public immutable rns;
  address public immutable resolver;
  INSAuction public immutable auction;

  constructor(INSUnified rns_, address resolver_, INSAuction auction_) {
    rns = rns_;
    auction = auction_;
    resolver = resolver_;
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
