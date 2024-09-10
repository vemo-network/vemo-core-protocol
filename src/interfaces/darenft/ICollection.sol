// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICollection {
    function safeMint(address to) external returns (uint256);

    function safeMintBatchWithTokenUrisAndRoyalty(
        address to,
        string[] calldata tokenUris,
        address receiver,
        uint96 royaltyRate
    ) external returns (uint256 startId, uint256 endId);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        returns (address receiver, uint256 royaltyAmount);
}
