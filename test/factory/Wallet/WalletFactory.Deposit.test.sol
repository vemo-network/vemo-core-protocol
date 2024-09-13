// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./WalletFactory.base.sol";
import "../../../src/accounts/AccountV3.sol";

contract WalletFactorDepositTest is Test, WalletFactoryBaseTest {
    address user1 = vm.addr(4);

    function testSingleCreate() public {
        vm.startPrank(user);
        address nftAddress = walletFactory.walletCollections(uint160(address(usdt)));
        (uint256 tokenId,) = walletFactory.createFor(
            nftAddress,
            address(userReceiver)
        );
        vm.stopPrank();

        // make sure we store the correct vesting data in ERC6551
        AccountV3 tba = AccountV3(payable(walletFactory.getTokenBoundAccount(nftAddress, tokenId)));
        (uint256 accountChainId, address accountNftAddress, uint256 accountTokenId) = IERC6551Account(tba).token();

        address walletAccount = walletFactory.getTokenBoundAccount(nftAddress, tokenId);
        address payable pAccount = payable(walletAccount);
        (accountChainId,  accountNftAddress,  accountTokenId) = IERC6551Account(pAccount).token();

        // allow anyone to deposit for the tba, take some fee
        uint256 depositAmount = 1000;

        vm.startPrank(user1);
        usdt.mint(user1, depositAmount);
        usdt.approve(address(walletFactory), depositAmount);

        walletFactory.depositTokens(address(usdt), address(tba), depositAmount);
        uint256 feeBps = walletFactory.depositFeeBps();

        assertEq(usdt.balanceOf(address(tba)), depositAmount - depositAmount * feeBps / 10000);
        assertEq(usdt.balanceOf(walletFactory.feeReceiver()), depositAmount * feeBps / 10000);
    }

}
