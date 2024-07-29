// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";

import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../../mock/DataRegistryV2.sol";
import "../../../src/accounts/VoucherAccount.sol";
import "../../../src/AccountRegistry.sol";
import "../../../src/VoucherFactory.sol";
import "../../../src/helpers/VemoVestingStruct.sol";

import "../../../src/interfaces/IVoucherFactory.sol";
import "../../../src/interfaces/IVoucherAccount.sol";
import "../../../src/helpers/DataStruct.sol";
import "../../../src/helpers/NFTDescriptor/NFTDescriptor.sol";

import "../../mock/NFT.sol";
import "../../mock/USDT.sol";
import "../../mock/USDC.sol";
import "../../mock/Factory.sol";

contract VoucherFactoryBaseTest is Test {
    uint256 defaultAdminPrivateKey = 1;
    uint256 userPrivateKey = 2;
    uint256 feeReceiverPrivateKey = 3;
    address defaultAdmin = vm.addr(defaultAdminPrivateKey);
    address user = vm.addr(userPrivateKey);
    address userReceiver = vm.addr(userPrivateKey+99);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant WRITER_ROLE = keccak256("WRITER_ROLE");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes constant BALANCE_KEY = "BALANCE";

    VoucherFactory voucherFactory;
    Factory factory = new Factory();
    NFT nft;
    DataRegistryV2 dataRegistry;
    AccountRegistry accountRegistry = new AccountRegistry();
    VoucherAccount accountImpl = new VoucherAccount();
    address account;
    USDT usdt = new USDT();
    USDC usdc = new USDC();

    NFTDescriptor globalDescriptor;

    function setUp() public {
        nft = new NFT(defaultAdmin);
        dataRegistry = new DataRegistryV2();
        dataRegistry.initialize(
            defaultAdmin, address(factory), "", DataRegistrySettings({disableComposable: true, disableDerivable: true})
        );
        address proxy = Upgrades.deployUUPSProxy(
            "VoucherFactory.sol:VoucherFactory",
            abi.encodeCall(
                VoucherFactory.initialize,
                (defaultAdmin, address(factory), address(dataRegistry), address(accountRegistry), address(accountImpl))
            )
        );

        globalDescriptor = NFTDescriptor(Upgrades.deployUUPSProxy(
            "NFTDescriptor.sol:NFTDescriptor",
            abi.encodeCall(
                NFTDescriptor.initialize,
                (defaultAdmin)
            )
        ));

        voucherFactory = VoucherFactory(proxy);
        vm.startPrank(defaultAdmin);

        nft.grantRole(MINTER_ROLE, address(voucherFactory));
        dataRegistry.grantRole(DEFAULT_ADMIN_ROLE, address(voucherFactory));
        dataRegistry.grantRole(WRITER_ROLE, address(voucherFactory));
        voucherFactory.setX(address(usdt), address(nft));

        vm.stopPrank();
    }
}
