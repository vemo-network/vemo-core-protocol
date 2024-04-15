// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev the ERC-165 identifier for this interface is `0xd63e236c`
interface IDerivable {
  struct DerivedToken {
    address collection;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
  }

  /**
    * @dev The registry MUST emit the Derive event upon successful deriving NFT.
    */
  event Derive(address underlyingCollection, uint256 underlyingTokenId, address derivedCollection, uint256 derivedTokenId, uint256 startTime, uint256 endTime);

  /**
    * @dev The registry MUST emit the Reclaim event upon successful reclaiming NFT.
    */
  event Reclaim(address underlyingCollection, uint256 underlyingTokenId, address derivedCollection, uint256 derivedTokenId);

  /**
    * @dev Derive NFT from an underlying NFT.
    *   
    * Emits Derive event.
    * @param underlyingCollection collection address of the underlying NFT
    * @param underlyingTokenId token ID of the underlying NFT
    * @param startTime Unix timestamp from which the derived NFT is usable
    * @param endTime Unix timestamp beyond which the derived NFT is unusable
    * @param royaltyRate royalty rate in basis point of derived NFT
    * @return a boolean value indicates the deriving is whether successful or not
    */
  function derive(address underlyingCollection, uint256 underlyingTokenId, uint256 startTime, uint256 endTime, uint256 royaltyRate) external returns (bool);

  /**
    * @dev Reclaim the underlying NFT upon expiration of derived NFT.
    *   
    * Emits Reclaim event.
    * @param underlyingCollection collection address of the underlying NFT
    * @param underlyingTokenId token ID of the underlying NFT    
    * @return a boolean value indicates the reclaiming is whether successful or not
    */
  function reclaim(address underlyingCollection, uint256 underlyingTokenId) external returns (bool);

  /**
    * @dev Returns the derived NFT of a specific underlying NFT.
    *       
    * @param underlyingCollection collection address of the underlying NFT
    * @param underlyingTokenId token ID of the underlying NFT    
    * @return the derived NFT
    */
  function derivedOf(address underlyingCollection, uint256 underlyingTokenId) external view returns (DerivedToken memory);

  /**
    * @dev Returns the underlying NFT of a specific derived NFT.
    *           
    * @param derivedTokenId token ID of the derived NFT    
    * @return the underlying NFT
    */
  function underlyingOf(uint256 derivedTokenId) external view returns (address, uint256);
  
  /**
    * @dev Returns boolean indicates whether the NFT is usable or not
    *   
    * @param collection collection address of the NFT        
    * @param tokenId token ID of the NFT    
    * @return boolean indicates whether the NFT is usable or not
    */
  function isUsable(address collection, uint256 tokenId) external view returns (bool);

  /**
    * @dev Returns boolean indicates whether the NFT is derivable or not
    *   
    * @param collection collection address of the NFT        
    * @param tokenId token ID of the NFT    
    * @return boolean indicates whether the NFT is derivable or not
    */
  function isDerivable(address collection, uint256 tokenId) external view returns (bool);

  /**
    * @dev Returns boolean indicates whether the NFT is reclaimable or not
    *   
    * @param collection collection address of the NFT        
    * @param tokenId token ID of the NFT    
    * @return boolean indicates whether the NFT is reclaimable or not
    */
  function isReclaimable(address requester, address collection, uint256 tokenId) external view returns (bool);
}