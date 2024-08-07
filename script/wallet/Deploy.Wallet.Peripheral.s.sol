
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

contract DeployVemoWalletSC is Script {
    // a Prime + 1
    uint256 salt = 0x8cb91e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // multicall address
        address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
        address registry = 0x000000006551c19487814612e58FE06813775758;
        address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;
        address tokenboundLayerZero = 0x0F220412Bf22E05EBcC5070D60fd7136A08aF22C;

        // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
        address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        vm.startBroadcast(deployerPrivateKey);

        AccountGuardian guardian = new AccountGuardian {salt: bytes32(salt)} (owner);
        AccountV3 implementation = new AccountV3{salt: bytes32(salt)}(
            entrypointERC4337, address(forwarder), address(registry), address(guardian));

        guardian.setTrustedImplementation(address(implementation), true);
        guardian.setTrustedExecutor(tokenboundLayerZero, true);

        AccountProxy accountProxy = new AccountProxy{salt: bytes32(salt)}(
           address(guardian), address(implementation)
        );
        
        vm.stopBroadcast();
    }
    
}
