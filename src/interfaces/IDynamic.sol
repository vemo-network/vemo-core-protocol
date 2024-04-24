// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev the ERC-165 identifier for this interface is `0xd212301b`
interface IDynamic {
    /**
     * @dev The registry MUST emit the Write event upon successful writing data.
     */
    event Write(address collection, uint256 tokenId, bytes32 key, bytes value);

    /**
     * @dev Write metadata for an NFT in terms of key/value.
     *
     * Emits Write event.
     * @param collection the collection address of NFT
     * @param tokenId the NFT token ID
     * @param key the Keccak256 hashed key
     * @param value the ABI encoded value
     */
    function write(address collection, uint256 tokenId, bytes32 key, bytes calldata value) external;

    /**
     * @dev Write batch metadata for multiple NFTs in terms of key/value.
     *
     * @param collection the collection address of NFT
     * @param startId the start NFT token ID of the batch
     * @param endId the end NFT token ID of the batch
     * @param key the Keccak256 hashed key
     * @param value the ABI encoded value
     */
    function writeBatch(address collection, uint256 startId, uint256 endId, bytes32 key, bytes calldata value)
        external;

    /**
     * @dev Write batch metadata for single NFT in terms of key/value.
     *
     * @param collection the collection address of NFT
     * @param tokenId the  NFT token ID
     * @param keys list of the Keccak256 hashed key
     * @param values list of the ABI encoded value
     */
    function writeBatchForSingleNFT(
        address collection,
        uint256 tokenId,
        bytes32[] calldata keys,
        bytes[] calldata values
    ) external;

    /**
     * @dev Return the value corresponding to specific key of an NFT.
     *
     * @param collection the collection address of NFT
     * @param tokenId the NFT token ID
     * @param key the Keccak256 hashed key
     * @return the ABI encoded value
     */
    function read(address collection, uint256 tokenId, bytes32 key) external view returns (bytes memory);
}
