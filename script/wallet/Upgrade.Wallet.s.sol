
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/NFTAccountDelegable.sol";
import "../../src/accounts/AccountProxy.sol";
import {WalletFactory} from "../../src/WalletFactory.sol";
import "./UUPSProxy.sol";
import {CollectionDeployer} from "../../src/CollectionDeployer.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";
import {NFTDelegationDescriptor} from "../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {NFTAccountDescriptor} from "../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {VePendleTerm} from "../../src/terms/VePendleTerm.sol";

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
  account v3  0xcb4a7FF79E90BDE163583f20BB96E8610b0b5829
  accountProxy  0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73
  account registry  0x000000006551c19487814612e58FE06813775758
  wallet factory proxy  0x5A72A673f0621dC3b39B59084a72b95706E75EFd

  collectionDeployer  0xa9457218CeD3Dcdd2ab54dFAe020b32da9480A19
  vemoNFTdescriptor  0x92C301E70Ee2062960D6A8456ea9f340AD2F79a9
  term  0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7
  descriptor  0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B
  vemoCollection  0xa815Fd40821b722765Daa326177E3832703C390f
  vePendle voter  0xe199E125a3cCA16A688D964C555b457Bdf7C6125
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
    address walletFactoryProxy = 0x5A72A673f0621dC3b39B59084a72b95706E75EFd;
    address guardianAddress = 0xC833002b8179716Ae225B7a2B3DA463C47B14F76;
    address accountProxyAddress = 0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73;
    address NFTCollectionAddress = 0x604873F647c6888c109e9fB28ea32De82D97806a;

    // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
    address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    uint160 vemoCollectionIndex = 123456;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // upgrade walletFactory
        // upgradeWalletFactory();
        WalletFactory proxy = WalletFactory(payable(walletFactoryProxy));

        // /**
        //  * Deploy new VemoWallet implementation
        //  */
        AccountGuardian guardian = AccountGuardian(guardianAddress);
        // // address accountv3Implementation = 0x42ea7f52E9D80637eB05a1Df4b067A182bD31AB5;
        // NFTAccountDelegable accountv3Implementation = new NFTAccountDelegable(
        //     address(entrypointERC4337), address(forwarder), address(registry), address(guardian)
        // );

        // // whitelist new implementation
        // guardian.setTrustedImplementation(address(accountv3Implementation), true);
        // proxy.setWalletImpl(address(accountv3Implementation));

        // console2.log("account v3 upgraded to ", address(accountv3Implementation));

        /**
         * deploy new components for role module including
         * 1. collection deployer
         * 2. NFT delegation descriptor
         * 3. vependleterm
         * 4. NFT delegation collection
         * */
        deployVemoRoleModule(proxy, guardian);

        vm.stopBroadcast();
    }

    function upgradeWalletFactory() private returns (address) {
        WalletFactory factory = new WalletFactory{salt: bytes32(salt)}();
        WalletFactory proxy = WalletFactory(payable(walletFactoryProxy));

        bytes memory data;
        proxy.upgradeToAndCall(address(factory), data);

        console2.log("walletfactory upgrade to implementation:", address(factory), "\n");

        return address(factory);
    }

    function deployVemoRoleModule(WalletFactory proxy, AccountGuardian guardian) public {
        // Deploy collection registry
        CollectionDeployer collectionRegistry = new CollectionDeployer{salt: bytes32(salt)}(walletFactoryProxy);
        proxy.setCollectionDeployer(address(collectionRegistry));
        console.log("CollectionDeployer is set to WalletFatory ", address(collectionRegistry));

        // vemo NFT account collection 
        // address vemoNFTdescriptor = Upgrades.deployUUPSProxy(
        //     "NFTAccountDescriptor.sol:NFTAccountDescriptor",
        //     abi.encodeCall(
        //         NFTAccountDescriptor.initialize,
        //         owner
        //     )
        // );

        // address vemoCollection = proxy.createWalletCollection(
        //     uint160(salt) + vemoCollectionIndex,
        //     "Vemo NFT Account",
        //     "VNA",
        //     0x92C301E70Ee2062960D6A8456ea9f340AD2F79a9
        // );
        // 0xc7b869d9BB168aa99B2E482C0aAE5582C2aCEEE2
        // address vemoCollection = 0xa815Fd40821b722765Daa326177E3832703C390f;
        // proxy.createFor(vemoCollection, 0x308C6c08735c5cB323FC78b956Dcae19CC008608);
        // deploy a new  descriptor
        // address descriptor = Upgrades.deployUUPSProxy(
        //     "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
        //     abi.encodeCall(
        //         NFTDelegationDescriptor.initialize,
        //         owner
        //     )
        // );

        // // // deploy a new term
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

        // term  0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7
        // descriptor  0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B
        address nftDlgAddress = proxy.createDelegateCollection(
            "vePENDLE Voter",
            "VPV",
            0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B, 
            0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7,
            0xa815Fd40821b722765Daa326177E3832703C390f
        );

        // console.log("vemoNFTdescriptor ", vemoNFTdescriptor);
        // console.log("vemoCollection ", vemoCollection);
        // console.log("vePendle voter ", nftDlgAddress);
        // console.log("term ", term);
        // console.log("descriptor ", descriptor);
    }
    
}
