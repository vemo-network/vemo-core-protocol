// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICollectionRegistry {
    /**
     * @dev The registry MUST emit the CollectionCreated event upon successful collection creation.
     */
    event CollectionCreated(
        address collection,
        address indexed implementation,
        uint256 collectionIndex,
        string  name,
        string  symbol
    );

    /**
     * @dev The registry MUST revert with CollectionCreationFailed error if the create2 operation fails.
     */
    error CollectionCreationFailed();

    /**
     * @dev Creates a ERC721 collection.
     *
     * If collection has already been created, returns the collection address without calling create2.
     *
     * Emits CollectionCreated event.
     *
     * @return collection The address of the ERC721 collection
     */
    function createCollection(
        address implementation,
        uint256 collectionIndex,
        string calldata name,
        string calldata symbol,
        bytes calldata initData
    ) external returns (address collection);

    /**
     * @dev Returns the computed ERC721 collection address for a non-fungible token.
     *
     * @return collection The address of the ERC721 collection
     */
    function collection(address implementation, uint256 collectionIndex, string calldata name,  string calldata symbol)
        external
        view
        returns (address collection);
}
