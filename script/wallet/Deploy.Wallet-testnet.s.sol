
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import {VemoWalletV3Upgradable} from "../../src/accounts/VemoWalletV3Upgradable.sol";
import "../../src/accounts/AccountProxy.sol";
import "../../src/WalletFactory.sol";
import "./UUPSProxy.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";
import "../../src/CollectionDeployer.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import "../../src/terms/VePendleTerm.sol";

/**
WalletFactory address: 0x4dC60D2348Cb5F3d14DB2bCa0Ca8923156B661E1 

NFT collection  0xD66C029A41cD75faD329FcC15D0E1F9AaF2C688f
nft Delegation Address  0x1Cb40278E360b1A50462d27FCe3278902C5ED414

guardian  0xd8cED359b0244c2495442e99bb5ED66a07c8cBd2
account v3  0xDD922C0a9849bf0d11D0831ADe49A1Ad9Cbb51a0
accountProxy  0x40E70BB7768e397A62A08f4945A8EC3860E90688
account registry  0x000000006551c19487814612e58FE06813775758
wallet factory proxy  0x4dC60D2348Cb5F3d14DB2bCa0Ca8923156B661E1
NFTCollection  0xD66C029A41cD75faD329FcC15D0E1F9AaF2C688f
Descriptor  0x07324c28D046434A59d3A54d711BA7C76f4b0B41
term  0x9C36815563ae0Eb9aF8801E48a6EAbA58745CC946 
layerzero OApp Testnet: 0x823b6CeA760716F40D6CA720a11f7459Fa361e9e
 */
contract DeployVemoWalletSC is Script {
    uint256 salt = 0x123456789987654321;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        /**
         * prod configuration
         */
        address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
        address registry = 0x000000006551c19487814612e58FE06813775758;
        address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;
        address tokenboundLayerZero = 0x823b6CeA760716F40D6CA720a11f7459Fa361e9e;

        // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
        address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        vm.startBroadcast(deployerPrivateKey);

        /**
         * uncomment if want to deploy from the scratch 
         */
        AccountGuardian guardian = new AccountGuardian {salt: bytes32(salt)} (owner);
        VemoWalletV3Upgradable accountv3Implementation = new VemoWalletV3Upgradable{salt: bytes32(salt)}(
            entrypointERC4337, address(forwarder), address(registry), address(guardian));

        guardian.setTrustedImplementation(address(accountv3Implementation), true);
        guardian.setTrustedExecutor(tokenboundLayerZero, true);

        AccountProxy accountProxy = new AccountProxy{salt: bytes32(salt)}(
           address(guardian), address(accountv3Implementation)
        );

        // address guardian = 0xC833002b8179716Ae225B7a2B3DA463C47B14F76;
        // address accountv3Implementation = 0xA94e04f900eF10670F0D730A49cEA5447fe6fcb8;
        // address accountProxy = 0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73;
        
        (address walletFactoryProxy, address walletFactoryImpl, address NFTCollection) = deployWalletFactory(
            owner,
            address(registry),
            address(accountProxy),
            address(accountv3Implementation)
        );

        console2.log("guardian ", address(guardian));
        console2.log("account v3 ", address(accountv3Implementation));
        console2.log("accountProxy ", address(accountProxy));
        console2.log("account registry ", address(registry));
        console2.log("wallet factory proxy ", walletFactoryProxy);
        console2.log("NFTCollection ", NFTCollection);


        /****
         * Deploy NFT Delegation, term, deployer
         */
        deployDelegationContracts(owner, address(guardian), walletFactoryProxy, NFTCollection);
        vm.stopBroadcast();
    }

    function deployWalletFactory(address owner, address registry, address accountProxy, address implementation) private returns (address, address, address) {
        WalletFactory factory = new WalletFactory{salt: bytes32(salt)}();

        console2.log("walletfactory address:", address(factory), "\n");

        UUPSProxy proxyWalletFactory = new UUPSProxy{salt: bytes32(salt)}(
            address(factory),
            abi.encodeWithSelector(WalletFactory.initialize.selector, owner, registry, accountProxy, implementation)
        );

        address proxyWalletFactoryAddress = address(proxyWalletFactory);

        console2.log("WalletFactory Proxy address:", address(proxyWalletFactory), "\n");

        // deploy collection deployer
        CollectionDeployer collectionRegistry = new CollectionDeployer(proxyWalletFactoryAddress);
        WalletFactory(payable(proxyWalletFactory)).setCollectionDeployer(address(collectionRegistry));

        address collection = deployVemoCollection(WalletFactory(payable(proxyWalletFactory)));

        return (proxyWalletFactoryAddress, address(factory), collection);
    }

    function deployVemoCollection(WalletFactory  factory) public returns(address){
        // WalletFactory factory = WalletFactory(payable(0x5A72A673f0621dC3b39B59084a72b95706E75EFd));
        address collection = factory.createWalletCollection(
            uint160(salt),
            "Vemo Smart Wallet",
            "VSW",
            "vemowallet"
        );

        console2.log("NFT collection ", collection);
        return collection;
    }

    function deployDelegationContracts(address owner, address guardian, address walletFactory, address nftCollection) public {
        address descriptor = Upgrades.deployUUPSProxy(
            "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
            abi.encodeCall(
                NFTDelegationDescriptor.initialize,
                owner
            )
        );
        console.log("Descriptor ", descriptor);

        // deploy a new term
        address term = Upgrades.deployUUPSProxy(
            "VePendleTerm.sol:VePendleTerm",
            abi.encodeCall(
                VePendleTerm.initialize,
                (
                    owner,
                    walletFactory,
                    guardian
                )
            )
        );
        console.log("term ", term);
        
        AccountGuardian(guardian).setTrustedImplementation(term, true);
        
        /**
         * term  0xEA8909794F435ee03528cfA8CE8e0cCa8D7535Ae
          descriptor  
          delegation 0x7F4282181243069B55379312196be53566a5FE03
         */
        address nftDlgAddress = WalletFactory(payable(walletFactory)).createDelegateCollection(
            "Vemo Delegation Wallet",
            "VDW", 
            descriptor,
            term,
            nftCollection
        );

        console.log("nftDlgAddress ", nftDlgAddress);

        AccountGuardian(guardian).setTrustedImplementation(nftDlgAddress, true);
    }
    
}
