// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFactory {
    // structs
    struct CollectionSettings {
        uint96 royaltyRate;
        bool isSoulBound;
        FreeMintableType isFreeMintable;
        bool isSemiTransferable;
    }

    enum FreeMintableType {
        NON_FREE_MINTABLE,
        FREE_MINT_COMMUNITY,
        FREE_MINT_WHITELIST
    }

    enum CollectionKind {
        ERC721Standard,
        ERC721A
    }

    // events
    event DataRegistryCreated(address dapp, address registry, string dappURI);
    event CollectionCreated(address owner, address collection, CollectionKind kind);
    event DerivedAccountCreated(address underlyingCollection, uint256 underlyingTokenId, address derivedAccount);
    event Fee(bytes32 action, uint256 fee);

    // commands
    function createDataRegistry(string calldata dappURI) external returns (address registry);

    function createCollection(
        string calldata name,
        string calldata symbol,
        CollectionSettings calldata settings,
        CollectionKind kind
    ) external returns (address);

    function createDerivedAccount(address underlyingCollection, uint256 underlyingTokenId) external returns (address);

    // queries
    function dataRegistryOf(address dapp) external view returns (address);

    function dappURI(address dapp) external view returns (string memory);

    function collectionOf(address owner, string calldata name, string calldata symbol)
        external
        view
        returns (address);

    function derivedAccountOf(address underlyingCollection, uint256 underlyingTokenId)
        external
        view
        returns (address);

    // DAO commands
    function setFee(bytes32 action, uint256 fee) external returns (bool);
}
