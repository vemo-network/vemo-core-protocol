// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./WalletFactory.base.sol";

contract WalletFactoryUtilsTest is Test, WalletFactoryBaseTest {
    address randomAdrr = vm.addr(99999);
    address randomToken = vm.addr(99999);

    function testSetWalletCollection() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setWalletCollection(uint160(address(usdc)), randomAdrr, "random");
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        walletFactory.setWalletCollection(uint160(address(usdc)), randomAdrr, "random");
        vm.stopPrank();

        assertEq(walletFactory.walletCollections(uint160(address(usdc))), randomAdrr);
    }

    function testCreateWalletCollection() public {
        vm.startPrank(randomAdrr);
        vm.expectRevert();
        address nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            "random"
        );
        vm.stopPrank();

        // could not create same nft with same person
        vm.startPrank(defaultAdmin);
        address _nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            "random"
        );
        vm.stopPrank();

    }

    function testCreateWalletCollectionSameNameSymbol() public {
        vm.startPrank(defaultAdmin);
        address _nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            "random"
        );
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        vm.expectRevert();
        _nft = walletFactory.createWalletCollection(
            uint160(randomToken) + 1,
            "random",
            "random",
            "random"
        );
        vm.stopPrank();
    }

    function testSetAccountRegistry() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setAccountRegistry(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        
        address _factory = walletFactory.accountRegistry();
        walletFactory.setAccountRegistry(randomToken);
        assertEq(walletFactory.accountRegistry(), randomToken);
        walletFactory.setAccountRegistry(_factory);
        vm.stopPrank();
    }

    function testSetWalletAccountImpl() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setWalletImpl(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = walletFactory.walletImpl();
        walletFactory.setWalletImpl(randomToken);
        assertEq(walletFactory.walletImpl(), randomToken);
        walletFactory.setWalletImpl(_factory);
        vm.stopPrank();
    }

    function testSetFeeReceiver() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setFeeReceiver(user);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        walletFactory.setFeeReceiver(user);
        assertEq(walletFactory.feeReceiver(), user);
        vm.stopPrank();
    }

    event WalletCreated(
        address indexed account,
        address indexed nftCollection,
        uint256 tokenId,
        address receiver,
        uint256 chainId
    );

    function testCreateTBA() public {
        
        vm.startPrank(user);
        vm.expectEmit(false, true, true, true);

        // We emit the event we expect to see.
        emit WalletCreated(address(this), address(usdt), 1, address(0), 1);

        walletFactory.createTBA(address(usdt), 1, 1);
        vm.stopPrank();
    }

}
