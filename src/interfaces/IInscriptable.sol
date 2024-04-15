// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev the ERC-165 identifier for this interface is `0x5193025c`
interface IInscriptable {
  /**
    * @dev Inscribe metadata on NFT in terms of key/value.
    *       
    * @param collection collection address of the NFT
    * @param tokenId token ID of the NFT
    * @param key the Keccak256 hashed key
    * @param value the ABI encoded value
    */
  function inscribe(address collection, uint256 tokenId, bytes32 key, bytes calldata value) external;
}