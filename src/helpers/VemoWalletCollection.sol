// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './NFTDescriptor/NFTAccount/INFTAccountDescriptor.sol';
import "../interfaces/IVoucherFactory.sol";
import "../interfaces/IVoucherAccount.sol";
import "../interfaces/ICollectionDeployer.sol";
import "../interfaces/IWalletFactory.sol";

contract VemoWalletCollection is ERC721, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => string) private _tokenURIs;
    address immutable public descriptor;
    address immutable public walletFactory;

    // this technique helps saving gas, store parameters on deployer, once the deployment is finished
    // all parameters will be removed
    constructor(
    ) ERC721(_ERC721Params(0), _ERC721Params(1)) Ownable(_ownerParam()) {
        (,,,walletFactory, descriptor,,) = ICollectionDeployer(msg.sender).parameters();
    }

    function _ERC721Params(uint8 index) private view returns (string memory) {
        (string memory name, string memory symbol,,,,,) = ICollectionDeployer(msg.sender).parameters();

        if (index == 0) return name;
        if (index == 1) return symbol;
    }

    function _ownerParam() private view returns (address owner) {
        (,,owner,,,,) = ICollectionDeployer(msg.sender).parameters();
    }

    function safeMint(address to, string memory uri) public onlyOwner returns (uint256 tokenId){
        tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
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
