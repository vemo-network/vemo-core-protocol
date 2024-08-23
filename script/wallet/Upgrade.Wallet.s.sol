// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountV3.sol";
import {VemoWalletV3Upgradable} from "../../src/accounts/VemoWalletV3Upgradable.sol";
import "../../src/accounts/AccountProxy.sol";
import "../../src/WalletFactory.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";
import "../../src/helpers/NFTDescriptor/NFTDescriptor.sol";
import "../../src/terms/VePendleTerm.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoWalletSC is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address walletFactoryProxy = 0xe2eBB6c62469f5afc0134DAbc9dD0e77F16eFba3;
        address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
        address registry = 0x000000006551c19487814612e58FE06813775758;
        address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;
        address tokenboundLayerZero = 0x823b6CeA760716F40D6CA720a11f7459Fa361e9e;
        address guardian = 0xBE67034116BBc44f86b4429D48B1e1FB2BdAd9b7;
        address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;


        // specific
        address term = 0x59800003Ee3D4dd0b668eA117579037E1efE58B5;
        vm.startBroadcast(deployerPrivateKey);

        // deploy new vemo wallet type
        VemoWalletV3Upgradable accountUpgradableImplementation = new VemoWalletV3Upgradable(
            address(entrypointERC4337), address(forwarder), address(registry), address(guardian)
        );

        // upgrade new walelt factory
        // WalletFactory implementation = new WalletFactory();
        WalletFactory proxy = WalletFactory(payable(walletFactoryProxy));
        // bytes memory data;
        // proxy.upgradeToAndCall(address(implementation), data);

        // set new wallet implementation 
        proxy.setWalletImpl(address(accountUpgradableImplementation));
        AccountGuardian(guardian).setTrustedImplementation(address(term), true);

        // // deploy a new descriptor
        // address descriptor = Upgrades.deployUUPSProxy(
        //     "NFTDescriptor.sol:NFTDescriptor",
        //     abi.encodeCall(
        //         NFTDescriptor.initialize,
        //         owner
        //     )
        // );

        // // deploy a new term
        // address term = Upgrades.deployUUPSProxy(
        //     "VePendleTerm.sol:VePendleTerm",
        //     abi.encodeCall(
        //         VePendleTerm.initialize,
        //         (
        //             owner,
        //             address(proxy),
        //             address(guardian)
        //         )
        //     )
        // );

        // address nftAddress = proxy.createDelegateCollection(
        //     "Vemo Delegation Wallet",
        //     "VDW",
        //     descriptor, 
        //     term
        // );
        // console.log("nftAddress ", nftAddress);
        console.log("term ", term);
        vm.stopBroadcast();
    }
}
