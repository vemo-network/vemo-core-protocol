// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";

import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "multicall-authenticated/Multicall3.sol";
import "erc6551/ERC6551Registry.sol";

import "../../../src/helpers/VemoVestingStruct.sol";
import "../../../src/AccountGuardian.sol";
// import "../../../src/interfaces/IWalletFactory.sol";
import "../../../src/helpers/DataStruct.sol";
import "../../../src/helpers/VemoWalletCollection.sol";
import {WalletFactory} from "../../../src/WalletFactory.sol";
import "../../../src/accounts/AccountV3.sol";

import "../../mock/NFT.sol";
import "../../mock/USDT.sol";
import "../../mock/USDC.sol";
import "../../mock/Factory.sol";

contract WalletFactoryBaseTest is Test {
    Multicall3 forwarder  = new Multicall3();
    uint256 defaultAdminPrivateKey = 1;
    uint256 userPrivateKey = 2;
    uint256 feeReceiverPrivateKey = 3;
    address defaultAdmin = vm.addr(defaultAdminPrivateKey);
    address user = vm.addr(userPrivateKey);
    address userReceiver = vm.addr(userPrivateKey+99);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes constant BALANCE_KEY = "BALANCE";

    WalletFactory walletFactory;
    Factory factory = new Factory();
    VemoWalletCollection nft;
    ERC6551Registry accountRegistry = new ERC6551Registry();
    AccountGuardian guardian = new AccountGuardian(address(this));
    AccountV3 accountImpl = new AccountV3( address(0x1), address(forwarder), address(accountRegistry), address(guardian));

    address account;
    USDT usdt = new USDT();
    USDC usdc = new USDC();

    function setUp() public {
        guardian.setTrustedImplementation(address(accountImpl), true);
        address proxy = Upgrades.deployUUPSProxy(
            "WalletFactory.sol:WalletFactory",
            abi.encodeCall(
                WalletFactory.initialize,
                (defaultAdmin, address(accountRegistry), address(accountImpl), address(accountImpl))
            )
        );

        walletFactory = WalletFactory(payable(proxy));

        vm.startPrank(defaultAdmin);

        address nftAddress = walletFactory.createWalletCollection(
            uint160(address(usdt)),
            "walletfactory",
            "walletfactory",
            "walletfactory"
        );
        nft = VemoWalletCollection(nftAddress);
        assertEq(
            walletFactory.walletCollections(uint160(address(usdt))),
            nftAddress
        );

        vm.stopPrank();
    }
}
