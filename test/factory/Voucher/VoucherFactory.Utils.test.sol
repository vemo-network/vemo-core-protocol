// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./VoucherFactory.base.sol";

contract FactoryUtilsTest is Test, VoucherFactoryBaseTest {
    address randomAdrr = vm.addr(99999);
    address randomToken = vm.addr(99999);

    function testTransferOwner() public {
        vm.startPrank(user);
        vm.expectRevert(bytes("only owner"));
        voucherFactory.transferOwner(user);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        voucherFactory.transferOwner(user);
        vm.stopPrank();

        assertEq(voucherFactory._owner(), user);
    }

    function testSetX() public {
        vm.startPrank(user);
        vm.expectRevert(bytes("only owner"));
        voucherFactory.setX(address(usdc), randomAdrr);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        voucherFactory.setX(address(usdc), randomAdrr);
        vm.stopPrank();

        assertEq(voucherFactory.getNftAddressFromMap(address(usdc)), randomAdrr);
    }

    function testCreateVoucherCollection() public {
        IFactory.CollectionSettings memory settings;

        vm.startPrank(randomAdrr);
        address nft = voucherFactory.createVoucherCollection(
            randomToken,
            "random",
            "random",
            settings
        );
        console.log(
            "voucherFactory.getNftAddressFromMap(randomToken) ", voucherFactory.getNftAddressFromMap(randomToken)
        );

        // nft owner must be randomAdrr
        // assertEq(AccessControl(nft).hasRole(0x00, randomAdrr), true);
        assertEq(voucherFactory.getNftAddressFromMap(randomToken), nft);
        vm.stopPrank();

        // could not create same nft with same person
        vm.startPrank(vm.addr(999998));
        address _nft = voucherFactory.createVoucherCollection(
            randomToken,
            "random",
            "random",
            settings
        );

        assertEq(_nft, nft);
        vm.stopPrank();
    }

    function testRemoveX() public {
        vm.startPrank(defaultAdmin);
        voucherFactory.setX(address(usdc), randomAdrr);
        assertEq(voucherFactory.getNftAddressFromMap(address(usdc)), randomAdrr);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert();
        voucherFactory.removeX(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        voucherFactory.removeX(address(usdc));
        vm.expectRevert();
        voucherFactory.getNftAddressFromMap(address(usdc));
        vm.stopPrank();
    }

    function testSetFactory() public {
        vm.startPrank(user);
        vm.expectRevert();
        voucherFactory.setFactory(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = voucherFactory.protocolFactoryAddress();
        voucherFactory.setFactory(randomToken);
        assertEq(voucherFactory.protocolFactoryAddress(), randomToken);
        voucherFactory.setFactory(_factory);
        vm.stopPrank();
    }

    function testSetDataRegistry() public {
         vm.startPrank(user);
        vm.expectRevert();
        voucherFactory.setDataRegistry(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = voucherFactory.dataRegistry();
        voucherFactory.setDataRegistry(randomToken);
        assertEq(voucherFactory.dataRegistry(), randomToken);
        voucherFactory.setDataRegistry(_factory);
        vm.stopPrank();
    }

    function testSetAccountRegistry() public {
        vm.startPrank(user);
        vm.expectRevert();
        voucherFactory.setAccountRegistry(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = voucherFactory.accountRegistry();
        voucherFactory.setAccountRegistry(randomToken);
        assertEq(voucherFactory.accountRegistry(), randomToken);
        voucherFactory.setAccountRegistry(_factory);
        vm.stopPrank();
    }

    function testSetVoucherAccountImpl() public {
        vm.startPrank(user);
        vm.expectRevert();
        voucherFactory.setVoucherAccountImpl(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = voucherFactory.voucherAccountImpl();
        voucherFactory.setVoucherAccountImpl(randomToken);
        assertEq(voucherFactory.voucherAccountImpl(), randomToken);
        voucherFactory.setVoucherAccountImpl(_factory);
        vm.stopPrank();
    }

}
