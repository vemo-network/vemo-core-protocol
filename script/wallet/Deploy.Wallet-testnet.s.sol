
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountV3.sol";
import "../../src/accounts/AccountProxy.sol";
import "../../src/WalletFactory.sol";
import "./UUPSProxy.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
/**
collection  0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB
guardian  0xBE67034116BBc44f86b4429D48B1e1FB2BdAd9b7
account v3  0x466a8D7e8ea7140ace60CD63d7D24199EE493238
accountProxy  0xF21e3FEde83E30Ab18fe7624C8c2b5DC7E4b0c18
account registry  0x000000006551c19487814612e58FE06813775758
wallet factory proxy  0xe2eBB6c62469f5afc0134DAbc9dD0e77F16eFba3
walletfactory address: 0xdd29355A71040C1122CfA60A6Dcf42c4C258EDc6 
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
        AccountV3 accountv3Implementation = new AccountV3{salt: bytes32(salt)}(
            entrypointERC4337, address(forwarder), address(registry), address(guardian));

        guardian.setTrustedImplementation(address(accountv3Implementation), true);
        guardian.setTrustedExecutor(tokenboundLayerZero, true);

        AccountProxy accountProxy = new AccountProxy{salt: bytes32(salt)}(
           address(guardian), address(accountv3Implementation)
        );

        // address guardian = 0xC833002b8179716Ae225B7a2B3DA463C47B14F76;
        // address accountv3Implementation = 0xA94e04f900eF10670F0D730A49cEA5447fe6fcb8;
        // address accountProxy = 0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73;
        
        (address walletFactoryProxy, address walletFactoryImpl) = deployWalletFactory(
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

        vm.stopBroadcast();
    }

    function deployWalletFactory(address owner, address registry, address accountProxy, address implementation) private returns (address, address) {
        WalletFactory factory = new WalletFactory{salt: bytes32(salt)}();

        console2.log("walletfactory address:", address(factory), "\n");

        UUPSProxy proxyWalletFactory = new UUPSProxy{salt: bytes32(salt)}(
            address(factory),
            abi.encodeWithSelector(WalletFactory.initialize.selector, owner, registry, accountProxy, implementation)
        );

        address proxyWalletFactoryAddress = address(proxyWalletFactory);

        console2.log("WalletFactory Proxy address:", address(proxyWalletFactory), "\n");

        deployVemoCollection(WalletFactory(payable(proxyWalletFactory)));

        return (proxyWalletFactoryAddress, address(factory));
    }

    function deployVemoCollection(WalletFactory  factory) public {
        // WalletFactory factory = WalletFactory(payable(0x5A72A673f0621dC3b39B59084a72b95706E75EFd));
        address collection = factory.createWalletCollection(
            uint160(salt),
            "Vemo Smart Wallet",
            "VSW",
            "vemowallet"
        );

        console2.log("collection ", collection);
    }

    
}
