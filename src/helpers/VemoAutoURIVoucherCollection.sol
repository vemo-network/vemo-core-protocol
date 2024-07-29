// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './NFTDescriptor/INFTDescriptor.sol';
import "../interfaces/IVoucherFactory.sol";
import "../interfaces/IVoucherAccount.sol";

/**
 * VemoVoucherCollection 
 * - ERC721
 * - dynamic tokenURI
 * - customizable NFTDescriptor
 */
contract VemoAutoURIVoucherCollection is ERC721, Ownable {
    uint256 private _nextTokenId;
    INFTDescriptor public descriptor;
    IVoucherFactory public voucherFactory;
    address voucherToken;

    constructor(
        address owner,
        address _voucherFactory,
        address _descriptor, 
        address _voucherToken
    ) ERC721(_collectionName(_voucherToken), _collectionSymbol(_voucherToken)) Ownable(owner) {
        voucherFactory = IVoucherFactory(_voucherFactory);
        descriptor = INFTDescriptor(_descriptor);
        voucherToken = _voucherToken;
    }

    function _collectionName(address token) private returns (string memory) {
        (bool success, bytes memory symbol) =  token.call(abi.encodeWithSignature("symbol()"));
        require(success == true);
        return string.concat(abi.decode(symbol, (string)), " Smart Voucher");
    }

    function _collectionSymbol(address token) private returns (string memory) {
        (bool success, bytes memory symbol) =  token.call(abi.encodeWithSignature("symbol()"));
        require(success == true);
        return string.concat(abi.decode(symbol, (string)), "SV");
    }

    function safeMint(address to) public onlyOwner returns (uint256 tokenId){
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IVoucherAccount tba = IVoucherAccount(
            IVoucherFactory(voucherFactory).getTokenBoundAccount(address(this), tokenId)
        );
        (uint256 balance, VestingSchedule[] memory schedules) = tba.getDataBalanceAndSchedule();

        return
            descriptor.constructTokenURI(
                INFTDescriptor.ConstructTokenURIParams({
                    nftId: tokenId,
                    balance: balance,
                    voucherToken: voucherToken,
                    nftAddress: address(this),
                    collectionName: name(),
                    schedules: schedules
                })
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
