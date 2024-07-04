
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
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoWalletSC is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // multicall address
        address forwarder = 0xcA11bde05977b3631167028862bE2a173976CA11;
        address registry = 0xa3937233d889c16d032fCaec16B3EE2690E2CE1A;
        address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;

        // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
        address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        vm.startBroadcast(deployerPrivateKey);

        // 0xb50D9B55b3F994ce5F881c4FAeA374cF69dBA3b1
        AccountGuardian guardian = new AccountGuardian(msg.sender);

        // 0x0deC1D7E2789f80084bB0d516381Cf80B0E7c5f7
        ERC6551Registry accountRegistry = new ERC6551Registry();

        //0x1146212217dBC5A3ee7954D55A194c232F4aDeAC
        AccountV3 implementation = new AccountV3(
            entrypointERC4337, address(forwarder), address(accountRegistry), address(guardian));

        guardian.setTrustedImplementation(address(implementation), true);
        guardian.setTrustedExecutor(0x0F220412Bf22E05EBcC5070D60fd7136A08aF22C, true);

        AccountProxy accountProxy = new AccountProxy(
           address(guardian), address(implementation)
        );

        /**
         * 0xf71E04F268Fb47F19E831Cb5a83f8d089AF72A6C
         * 0xd275BbdfD831E4E9Ee40e0B1DCA69df7097763AB
           impl 0xb367f1b4ca9610B476389f9eb4A2e761E3de9972
           proxy 0x8D495F870b68DEC3A6B67BC4846D4F916E192d6C

           new version with access control
           Contract Address: guardian: 0xA64D859FE34Bb6C11e226e8260A296a9c9523071
            implementation: 0x116fb3beBaF4aa317eb5Af590AfE267d15f926D1
            impl 0xD3FCae5c87Eec300E1Ce7911200F068582bdaBee
            proxy: 0x8E609d10053Bbd2BFcF6827d80B8a5923C51cf2d
         */
        address proxy = Upgrades.deployUUPSProxy(
            "WalletFactory.sol",
            abi.encodeCall(
                WalletFactory.initialize,
                (
                    owner,
                    address(accountRegistry),
                    address(accountProxy),
                    address(implementation)
                )
            )
        );

        console.logAddress(address(guardian)); // 0xb50D9B55b3F994ce5F881c4FAeA374cF69dBA3b1
        console.logAddress(address(implementation)); // 0x1146212217dBC5A3ee7954D55A194c232F4aDeAC
        console.logAddress(address(accountProxy)); // 0xEA8909794F435ee03528cfA8CE8e0cCa8D7535Ae
        console.logAddress(address(accountRegistry)); // 0xD629D25e20F26587C2Ee608fA0ebCA3aD4d00c6D
        console.logAddress(address(proxy)); // 0xbd29f427d04Df4c89c5c5616e866c365a6Bf3682
        vm.stopBroadcast();
    }
}
