// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev the ERC-165 identifier for this interface is `0x17e6e974`
interface IComposable {
  struct Token {
    address collection;
    uint256 tokenId;
  }

  /**
    * @dev The registry MUST emit the Compose event upon successful composing data.
    */
  event Compose(address srcCollection, uint256 srcTokenId, address descCollection, uint256 descTokenId, bytes32[] keyNames);

  /**
    * @dev Compose metadata from source NFT to dest NFT.
    *   
    * Emits Compose event.
    * @param srcToken source NFT
    * @param descToken dest NFT
    * @param keyNames the key array to be composed from source to dest   
    * @return a boolean value indicates the composing is whether successful or not
    */
  function compose(Token calldata srcToken, Token calldata descToken, bytes32[] calldata keyNames) external returns (bool);
}