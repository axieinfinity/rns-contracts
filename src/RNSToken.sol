// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC165, AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC721Metadata, IERC721, ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC721Pausable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Nonce } from "contract-template/refs/ERC721Nonce.sol";
import { INSUnified } from "./interfaces/INSUnified.sol";
import { IERC721State } from "contract-template/refs/IERC721State.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract RNSToken is
  AccessControlEnumerable,
  ERC721Nonce,
  ERC721Burnable,
  ERC721Pausable,
  ERC721Enumerable,
  IERC721State,
  INSUnified
{
  using Strings for *;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @dev Gap for upgradeability.
  uint256[50] private ____gap;

  uint256 internal _idCounter;
  string internal _baseTokenURI;

  modifier onlyMinted(uint256 tokenId) {
    _requireMinted(tokenId);
    _;
  }

  /// @inheritdoc INSUnified
  function setBaseURI(string calldata baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setBaseURI(baseTokenURI);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /// @dev Override {IERC721Metadata-name}.
  function name() public view virtual override(ERC721, IERC721Metadata) returns (string memory) {
    return "Ronin Name Service";
  }

  /// @dev Override {IERC721Metadata-symbol}.
  function symbol() public view virtual override(ERC721, IERC721Metadata) returns (string memory) {
    return "RNS";
  }

  /// @inheritdoc INSUnified
  function totalMinted() external view virtual returns (uint256) {
    return _idCounter;
  }

  /// @dev Override {IERC721Metadata-tokenURI}.
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721, IERC721Metadata)
    onlyMinted(tokenId)
    returns (string memory)
  {
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string.concat(baseURI, address(this).toHexString(), "/", tokenId.toString()) : "";
  }

  /// @dev Override {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControlEnumerable, ERC721Enumerable, IERC165)
    returns (bool)
  {
    return super.supportsInterface(interfaceId) || interfaceId == type(INSUnified).interfaceId;
  }

  /// @dev Override {ERC721-_mint}.
  function _mint(address to, uint256 tokenId) internal virtual override {
    unchecked {
      ++_idCounter;
    }
    super._mint(to, tokenId);
  }

  /**
   * @dev Helper method to set base uri.
   */
  function _setBaseURI(string calldata baseTokenURI) internal virtual {
    _baseTokenURI = baseTokenURI;
    emit BaseURIUpdated(_msgSender(), baseTokenURI);
  }

  /// @dev Override {ERC721-_beforeTokenTransfer}.
  function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal
    virtual
    override(ERC721, ERC721Nonce, ERC721Enumerable, ERC721Pausable)
  {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }

  /// @dev Override {ERC721-_baseURI}.
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
}
