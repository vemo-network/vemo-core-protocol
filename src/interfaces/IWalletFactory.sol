// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./darenft/IFactory.sol";

interface IWalletFactory {
    event WalletCreated(
        address indexed account,
        address indexed nftCollection,
        uint256 tokenId,
        address receiver
    );

    event CollectionCreated(
        address indexed collection,
        uint256 indexed collectionIndex,
        string  name,
        string  symbol,
        string  dappURI
    );

    event TBACreated(
        address indexed collection,
        uint256 indexed collectionIndex,
        address  account,
        uint256  chainId
    );

    function createWalletCollection(
        uint160 collectionIndex,
        string calldata name,
        string calldata symbol,
        string calldata dappURI
    ) external returns (address);

    function create(address nftAddress, string memory tokenUri) external returns (uint256 tokenId, address tba);

    function createFor(address nftAddress, string memory tokenUri, address receiver) external returns (uint256, address);

    function createTBA(address nftAddress, uint256 tokenId, uint256 chainId) external; 
}

