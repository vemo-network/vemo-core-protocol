// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './NFTDescriptor/DelegationURI/INFTDelegationDescriptor.sol';
import "../interfaces/IWalletFactory.sol";
import "../interfaces/IExecutionTerm.sol";
import "../interfaces/IDelegationCollection.sol";
import "../interfaces/ICollectionDeployer.sol";

import "forge-std/console.sol";
/**
 * VemoDelegateCollection 
 * - ERC721
 * - dynamic tokenURI
 * - customizable NFTDescriptor
 * - link with a specific term - which determines a transaction from delegate owner executable
 */
contract VemoDelegationCollection is ERC721, Ownable, IDelegationCollection  {
    uint256 private _nextTokenId;
    address immutable public descriptor;
    address immutable public walletFactory;
    
    address immutable public term;
    address immutable public issuer;

    // tokenId => start_revoking_time
    mapping(uint256 => uint256) public  revokingRoles;

    event Delegate(address indexed owner, address indexed delegated, uint256 indexed tokenId);
    error InRevokingPeriod(uint256);
    error Unburnable(uint256);
    
    constructor(
    ) ERC721(_ERC721Params(0), _ERC721Params(1)) Ownable(_ownerParam()) {
        (,,,walletFactory, descriptor, term,issuer) = ICollectionDeployer(msg.sender).parameters();
    }

    function _ERC721Params(uint8 index) private view returns (string memory) {
        (string memory name, string memory symbol,,,,,) = ICollectionDeployer(msg.sender).parameters();

        if (index == 0) return name;
        if (index == 1) return symbol;
    }

    function _ownerParam() private view returns (address owner) {
        (,,owner,,,,) = ICollectionDeployer(msg.sender).parameters();
    }

    modifier onlyTBA(uint256 tokenId) {
        _checkRole(tokenId);
        _;
    }

    function _checkRole(uint256 tokenId) internal view virtual {
        address _tba = IWalletFactory(walletFactory).getTokenBoundAccount(issuer, tokenId);
        require(_tba == _msgSender());
    }

    // function safeMint(uint256 tokenId, address to) public onlyOwner returns (uint256){
    //     _safeMint(to, tokenId);
    //     return tokenId;
    // }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address _tba = IWalletFactory(walletFactory).getTokenBoundAccount(issuer, tokenId);
        require(_tba != address(0));
        return
            INFTDelegationDescriptor(descriptor).constructTokenURI(
                INFTDelegationDescriptor.ConstructTokenURIParams({
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

    function burn(uint256 tokenId) public virtual  {
        address _owner = _ownerOf(tokenId);
        address _tba = IWalletFactory(walletFactory).getTokenBoundAccount(issuer, tokenId);
       
        if (_owner == tx.origin || 
            (
                _tba == _msgSender() &&
                revokingRoles[tokenId] > 0 && revokingRoles[tokenId] < block.timestamp
            )
        ) {
            _rmDelegate(tokenId);
        } else {
            revert Unburnable(tokenId);
        }
    }

    function delegate(uint256 tokenId, address receiver) public onlyTBA(tokenId) {
        address _owner = _ownerOf(tokenId);
        
        require(_owner == address(0));
        
        _safeMint(receiver, tokenId);
    }

    function revoke(uint256 tokenId) public onlyTBA(tokenId) {
        address _owner = _ownerOf(tokenId);
        if (_owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        
        if (revokingRoles[tokenId] == 0) {
            revokingRoles[tokenId] = block.timestamp + IExecutionTerm(term).revokeTimeout();
        } else if (revokingRoles[tokenId] < block.timestamp) {
            _rmDelegate(tokenId);
        } else {
            revert InRevokingPeriod(tokenId);
        }
    }

    function _rmDelegate(uint256 tokenId) private {
        _update(address(0), tokenId, _ownerOf(tokenId));
        revokingRoles[tokenId] = 0;
    }

    function tba(uint256 tokenId) external view returns(address) {
        return IWalletFactory(walletFactory).getTokenBoundAccount(issuer, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override virtual {
        require(revokingRoles[tokenId] == 0);

        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

}
