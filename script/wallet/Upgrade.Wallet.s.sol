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
import "../../src/CollectionDeployer.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";
import "../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import "../../src/terms/VePendleTerm.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 collectionRegistry  0xD8C9587bB79a27c2307845E4427A172F8393c022
  nftDlgAddress  0x2C3E236EAE4e8E0a5901a088ABD2bddC33F7D014
  term  0xc97A3CC29D383cE05E7DcA3fAd3e0B8DE9260d20
  descriptor  0x03b2C4c788ECca804100F706C0646e831CB5227f
 */
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
        address descriptor = 0x03b2C4c788ECca804100F706C0646e831CB5227f;
        address walletCollectionTestnet = 0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB;
        // address term = 0x79198D9204bFa74527A283ce08CB3566F07615Cb;

        // specific
        // address term = 0x59800003Ee3D4dd0b668eA117579037E1efE58B5;
        vm.startBroadcast(deployerPrivateKey);

        // // deploy new vemo wallet type
        // VemoWalletV3Upgradable implementation = new VemoWalletV3Upgradable(
        //     address(entrypointERC4337), address(forwarder), address(registry), address(guardian)
        // );
        // AccountGuardian(guardian).setTrustedImplementation(address(implementation), true);

        // upgrade new walelt factory
        // WalletFactory implementation = new WalletFactory();

        WalletFactory proxy = WalletFactory(payable(walletFactoryProxy));
        // bytes memory data;
        // proxy.upgradeToAndCall(address(implementation), data);

        // create collection registry
        // CollectionDeployer collectionRegistry = new CollectionDeployer(walletFactoryProxy);
        // proxy.setCollectionDeployer(address(collectionRegistry));
        // console.log("collectionRegistry ", address(collectionRegistry));

        // proxy.setWalletImpl(address(implementation));

//         // address walletFactoryProxy = 0xe2eBB6c62469f5afc0134DAbc9dD0e77F16eFba3;
//         // address guardian = 0xBE67034116BBc44f86b4429D48B1e1FB2BdAd9b7;

//         // specific
//         // address term = 0x59800003Ee3D4dd0b668eA117579037E1efE58B5;
//         vm.startBroadcast(deployerPrivateKey);

        // // deploy a new descriptor
        // address descriptor = Upgrades.deployUUPSProxy(
        //     "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
        //     abi.encodeCall(
        //         NFTDelegationDescriptor.initialize,
        //         owner
        //     )
        // );

        // // deploy a new term
        address term = Upgrades.deployUUPSProxy(
            "VePendleTerm.sol:VePendleTerm",
            abi.encodeCall(
                VePendleTerm.initialize,
                (
                    owner,
                    address(proxy),
                    address(guardian)
                )
            )
        );

        AccountGuardian(guardian).setTrustedImplementation(term, true);

        address nftDlgAddress = proxy.createDelegateCollection(
            "Vemo Delegation Wallet",
            "VDW",
            descriptor, 
            term,
            walletCollectionTestnet
        );

        console.log("nftDlgAddress ", nftDlgAddress);
        console.log("term ", term);
        console.log("descriptor ", descriptor);
        // console.log("collectionRegistry ", address(collectionRegistry));

//         // create collection registry
//         // CollectionDeployer collectionRegistry = new CollectionDeployer(walletFactoryProxy);
//         // proxy.setCollectionDeployer(address(collectionRegistry));
        
//         // proxy.setWalletImpl(address(implementation));

//         // (uint256 tokenId, address tba) = proxy.create(0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB, "");
//         // console.log(tokenId, tba);

//         // set new wallet implementation 

//         // // deploy a new descriptor
//         // address descriptor = Upgrades.deployUUPSProxy(
//         //     "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
//         //     abi.encodeCall(
//         //         NFTDelegationDescriptor.initialize,
//         //         owner
//         //     )
//         // );

//         // // deploy a new term
//         // address term = Upgrades.deployUUPSProxy(
//         //     "VePendleTerm.sol:VePendleTerm",
//         //     abi.encodeCall(
//         //         VePendleTerm.initialize,
//         //         (
//         //             owner,
//         //             address(proxy),
//         //             address(guardian)
//         //         )
//         //     )
//         // );

//         VePendleTerm termImplementation = new VePendleTerm();

//         VePendleTerm termProxy = VePendleTerm(payable(walletFactoryProxy));
//         termProxy.upgradeToAndCall(address(walletImplementation), data);

//         // AccountGuardian(guardian).setTrustedImplementation(0x2C3E236EAE4e8E0a5901a088ABD2bddC33F7D014, true);
        
//         /**
//          * term  0xEA8909794F435ee03528cfA8CE8e0cCa8D7535Ae
//           descriptor  
//           delegation 0x7F4282181243069B55379312196be53566a5FE03
//          */
//         // address nftDlgAddress = proxy.createDelegateCollection(
//         //     "Vemo Delegation Wallet",
//         //     "VDW",
//         //     0x03b2C4c788ECca804100F706C0646e831CB5227f, 
//         //     descriptor,
//         //     0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB
//         // );

//         // console.log("nftDlgAddress ", nftDlgAddress);
//         // // console.log("term ", term);
//         // console.log("descriptor ", descriptor);
//         // console.log("collectionRegistry ", address(collectionRegistry));

//         // proxy.delegate(
//         //     0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB,
//         //     0x7F4282181243069B55379312196be53566a5FE03,
//         //     tokenId,
//         //     owner
//         // );

//         vm.stopBroadcast();
    }
}
