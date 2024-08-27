// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './NFTDescriptor/DelegationURI/INFTDelegationDescriptor.sol';
import "../interfaces/IWalletFactory.sol";
import "../interfaces/IDelegationCollection.sol";
import "../interfaces/ICollectionRegistry.sol";

/**
 * VemoDelegateCollection 
 * - ERC721
 * - dynamic tokenURI
 * - customizable NFTDescriptor
 * - link with a specific term - which determines a transaction from delegate owner executable
 */
contract VemoDelegationCollection is ERC721, Ownable, IDelegationCollection  {
    uint256 private _nextTokenId;
    address public descriptor;
    address public walletFactory;
    
    address public term;
    address public issuer;

    constructor(
    ) ERC721(_ERC721Params(0), _ERC721Params(1)) Ownable(_ownerParam()) {
        (,,,walletFactory, descriptor, term,issuer) = ICollectionRegistry(msg.sender).parameters();
    }

    function _ERC721Params(uint8 index) private view returns (string memory) {
        (string memory name, string memory symbol,,,,,) = ICollectionRegistry(msg.sender).parameters();

        if (index == 0) return name;
        if (index == 1) return symbol;
    }

    function _ownerParam() private view returns (address owner) {
        (,,owner,,,,) = ICollectionRegistry(msg.sender).parameters();
    }

    function safeMint(uint256 tokenId, address to) public onlyOwner returns (uint256){
        _safeMint(to, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            INFTDelegationDescriptor(descriptor).constructTokenURI(
                INFTDelegationDescriptor.ConstructTokenURIParams({
                    nftId: tokenId,
                    nftAddress: address(this),
                    collectionName: name(),
                    tba: IWalletFactory(walletFactory).getTokenBoundAccount(address(this), tokenId)
                })
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public virtual {
        _update(address(0), tokenId, _msgSender());
    }

}
