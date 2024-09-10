// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./WalletFactory.base.sol";
import "../../../src/accounts/AccountV3.sol";

contract WalletFactoryCreateTest is Test, WalletFactoryBaseTest {
    address user1 = vm.addr(4);

    function testSingleCreate() public {
        vm.startPrank(user);
        address nftAddress = walletFactory.walletCollections(uint160(address(usdt)));
        console.log(nftAddress);

        (uint256 tokenId, address _tba) = walletFactory.create(nftAddress);
        vm.stopPrank();

        // // make sure we store the correct vesting data in ERC6551
        AccountV3 tba = AccountV3(payable(walletFactory.getTokenBoundAccount(nftAddress, tokenId)));
        (uint256 accountChainId, address accountNftAddress, uint256 accountTokenId) = IERC6551Account(tba).token();
        assertEq(accountNftAddress, nftAddress);

        assertEq(address(nft), nftAddress);
        assertEq(user, nft.ownerOf(tokenId));

        address walletAccount = walletFactory.getTokenBoundAccount(nftAddress, tokenId);
        address payable pAccount = payable(walletAccount);
        ( accountChainId,  accountNftAddress,  accountTokenId) = IERC6551Account(pAccount).token();
        assertEq(block.chainid, accountChainId);
        assertEq(nftAddress, accountNftAddress);
        assertEq(tokenId, accountTokenId);
    }

}
