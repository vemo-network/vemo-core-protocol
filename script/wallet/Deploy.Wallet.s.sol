
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
import {NFTAccountDescriptor} from "../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
  walletfactory address: 0x2D675d0C90D39751FA33d7b2498D556142590a36 
  WalletFactory Proxy address: 0x5A72A673f0621dC3b39B59084a72b95706E75EFd 

  guardian  0xC833002b8179716Ae225B7a2B3DA463C47B14F76
  account v3  0xA94e04f900eF10670F0D730A49cEA5447fe6fcb8
  accountProxy  0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73
  account registry  0x000000006551c19487814612e58FE06813775758
  wallet factory proxy  0x5A72A673f0621dC3b39B59084a72b95706E75EFd

  ------------
  walletfactory address: 0x2D675d0C90D39751FA33d7b2498D556142590a36 
  WalletFactory Proxy address: 0x5A72A673f0621dC3b39B59084a72b95706E75EFd 
  guardian  0xC833002b8179716Ae225B7a2B3DA463C47B14F76
  account v3  0xA94e04f900eF10670F0D730A49cEA5447fe6fcb8
  accountProxy  0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73
  account registry  0x000000006551c19487814612e58FE06813775758
  wallet factory proxy  0x5A72A673f0621dC3b39B59084a72b95706E75EFd
 */

contract DeployVemoWalletSC is Script {
    // a Prime
    uint256 salt = 0x8cb91e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c;

    /**
     * prod configuration
     */
    address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
    address registry = 0x000000006551c19487814612e58FE06813775758;
    address owner = 0x308C6c08735c5cB323FC78b956Dcae19CC008608;
    address tokenboundLayerZero = 0x96f0445246B19Fa098f8bb4dfA907eD38F6155d5;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

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
        address vemoNFTdescriptor = Upgrades.deployUUPSProxy(
            "NFTAccountDescriptor.sol:NFTAccountDescriptor",
            abi.encodeCall(
                NFTAccountDescriptor.initialize,
                owner
            )
        );

        address collection = factory.createWalletCollection(
            uint160(salt),
            "Vemo Smart Wallet",
            "VSW",
            vemoNFTdescriptor
        );

        console2.log("collection ", collection);
    }

    
}
