// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './NFTDescriptor/DelegationURI/INFTDelegationDescriptor.sol';
import "../interfaces/IWalletFactory.sol";
import "../interfaces/IDelegationCollection.sol";

/**
 * VemoDelegateCollection 
 * - ERC721
 * - dynamic tokenURI
 * - customizable NFTDescriptor
 * - link with a specific term - which determines a transaction from delegate owner executable
 */
contract VemoDelegationCollection is ERC721, Ownable, IDelegationCollection  {
    uint256 private _nextTokenId;
    INFTDelegationDescriptor public descriptor;
    IWalletFactory public walletFactory;
    
    address public term;
    address public issuer;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _walletFactory,
        address _descriptor, 
        address _term,
        address _issuer
    ) ERC721(_name, _symbol) Ownable(_owner) {
        walletFactory = IWalletFactory(_walletFactory);
        descriptor = INFTDelegationDescriptor(_descriptor);
        term = _term;
        issuer = _issuer;
    }

    function safeMint(uint256 tokenId, address to) public onlyOwner returns (uint256){
        _safeMint(to, tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            descriptor.constructTokenURI(
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
