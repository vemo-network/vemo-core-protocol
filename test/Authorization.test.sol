// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";

import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/DataRegistryV2.sol";
import "../src/ERC6551Account.sol";
import "../src/ERC6551Registry.sol";
import "../src/Voucher.sol";
import "../src/Common.sol";

import "../src/interfaces/IVemoVoucher.sol";
import "../src/interfaces/IERC6551Account.sol";
import "../src/helpers/DataStruct.sol";

import "./mock/NFT.sol";
import "./mock/USDT.sol";
import "./mock/USDC.sol";
import "./mock/Factory.sol";

contract VoucherAuthTest is Test {
    uint256 defaultAdminPrivateKey = 1;
    uint256 userPrivateKey = 2;
    uint256 feeReceiverPrivateKey = 3;
    address defaultAdmin = vm.addr(defaultAdminPrivateKey);
    address user = vm.addr(userPrivateKey);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant WRITER_ROLE = keccak256("WRITER_ROLE");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes private constant BALANCE_KEY = "BALANCE";

    Voucher voucher;
    Factory factory = new Factory();
    NFT nft;
    DataRegistryV2 dataRegistry;
    ERC6551Registry accountRegistry = new ERC6551Registry();
    ERC6551Account accountImpl = new ERC6551Account();
    address account;
    USDT usdt = new USDT();
    USDC usdc = new USDC();

    function setUp() public {
        nft = new NFT(defaultAdmin);
        dataRegistry = new DataRegistryV2();
        dataRegistry.initialize(
            defaultAdmin, address(factory), "", DataRegistrySettings({disableComposable: true, disableDerivable: true})
        );
        address proxy = Upgrades.deployUUPSProxy(
            "Voucher.sol:Voucher",
            abi.encodeCall(
                Voucher.initialize,
                (defaultAdmin, address(factory), address(dataRegistry), address(accountRegistry), address(accountImpl))
            )
        );
        
        voucher = Voucher(proxy);
        vm.startPrank(defaultAdmin);
        nft.grantRole(MINTER_ROLE, address(voucher));
        dataRegistry.grantRole(DEFAULT_ADMIN_ROLE, address(voucher));
        dataRegistry.grantRole(WRITER_ROLE, address(voucher));
        vm.stopPrank();
    }

    function testTransferOwner() public {
        vm.startPrank(user);
        vm.expectRevert(bytes("only owner"));
        voucher.transferOwner(user);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        voucher.transferOwner(user);
        vm.stopPrank();

        assertEq(voucher._owner(), user);
    }
}
