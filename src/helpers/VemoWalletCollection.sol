// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './NFTDescriptor/NFTAccount/INFTAccountDescriptor.sol';
import "../interfaces/IVoucherFactory.sol";
import "../interfaces/IVoucherAccount.sol";
import "../interfaces/ICollectionDeployer.sol";
import "../interfaces/IWalletFactory.sol";

contract VemoWalletCollection is ERC721, Ownable {
    uint256 private _nextTokenId;
    address immutable public descriptor;
    address immutable public walletFactory;

    // this technique helps saving gas, store parameters on deployer, once the deployment is finished
    // all parameters will be removed
    constructor(
    ) ERC721(_ERC721Params(0), _ERC721Params(1)) Ownable(_ownerParam()) {
        walletFactory =  ICollectionDeployer(msg.sender).walletFactory();
        descriptor =  ICollectionDeployer(msg.sender).descriptor();
    }

    function _ERC721Params(uint8 index) private view returns (string memory) {
        string memory name =  ICollectionDeployer(msg.sender).name();
        string memory symbol =  ICollectionDeployer(msg.sender).symbol();

        if (index == 0) return name;
        if (index == 1) return symbol;
    }

    function _ownerParam() private view returns (address owner) {
        owner = ICollectionDeployer(msg.sender).collectionOwner();
    }

    function safeMint(address to) public onlyOwner returns (uint256 tokenId){
        tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address _tba = IWalletFactory(walletFactory).getTokenBoundAccount(address(this), tokenId);
        require(_tba != address(0));
        return
            INFTAccountDescriptor(descriptor).constructTokenURI(
                INFTAccountDescriptor.ConstructTokenURIParams({
                    nftId: tokenId,
                    nftAddress: address(this),
                    collectionName: name(),
                    tba: _tba
                })
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
