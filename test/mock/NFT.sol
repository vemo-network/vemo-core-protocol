// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFT is ERC721Royalty, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint8 private constant MAX_BATCH_SIZE = 100;
    uint256 private _nextTokenId;
    mapping(uint256 tokenId => string) private _tokenUris;

    constructor(address defaultAdmin) ERC721("NFT", "NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://google.com";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenUris[tokenId];
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function safeMintBatchWithTokenUrisAndRoyalty(
        address to,
        string[] calldata tokenUris,
        address receiver,
        uint96 royaltyRate
    ) external onlyRole(MINTER_ROLE) returns (uint256 startId, uint256 endId) {
        return _mintBatchWithTokenUrisAndRoyalty(to, tokenUris, receiver, royaltyRate);
    }

    function _mintBatchWithTokenUrisAndRoyalty(
        address to,
        string[] calldata tokenUris,
        address receiver,
        uint96 royaltyRate
    ) private returns (uint256 startId, uint256 endId) {
        require(tokenUris.length <= MAX_BATCH_SIZE, "Batch size MUST not exceed limit");
        uint8 j;
        uint256 tokenId;
        startId = _nextTokenId;

        while (j < tokenUris.length && j < MAX_BATCH_SIZE) {
            tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            _tokenUris[tokenId] = tokenUris[j];
            if (royaltyRate > 0) {
                _setTokenRoyalty(tokenId, receiver, royaltyRate);
            }
            j++;
        }

        return (startId, _nextTokenId - 1);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Royalty, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
