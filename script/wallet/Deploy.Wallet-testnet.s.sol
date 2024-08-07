
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

// testnet
// address guardian = 0xb2E8034f7E135A7d45535FA40d204F1FDF158C3C;
// address accountv3Implementation = 0xF7e78A4f68655db2fa561B3bC0a6216805b0a28a;
// address accountProxy = 0x3f3EE2F1156f987c1274b1429fc11599b95bE56A;
// wallet factory : 0x16B73f4EF7A85279dc52f0D3c116E1fc3435Ea00
// wallet factory implement: 0x2D675d0C90D39751FA33d7b2498D556142590a36
// address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
// address registry = 0x000000006551c19487814612e58FE06813775758;
// address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;
// address tokenboundLayerZero = 0x0F220412Bf22E05EBcC5070D60fd7136A08aF22C;

contract DeployVemoWalletSC is Script {
    // a Prime
    uint256 salt = 0x8cb91e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        /**
         * prod configuration
         */
        address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
        address registry = 0x000000006551c19487814612e58FE06813775758;
        address owner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;
        address tokenboundLayerZero = 0x0F220412Bf22E05EBcC5070D60fd7136A08aF22C;

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
        
        // testnet
        // address guardian = 0xb2E8034f7E135A7d45535FA40d204F1FDF158C3C;
        // address accountv3Implementation = 0xF7e78A4f68655db2fa561B3bC0a6216805b0a28a;
        // address accountProxy = 0x3f3EE2F1156f987c1274b1429fc11599b95bE56A;

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

        return (proxyWalletFactoryAddress, address(factory));
    }

    
}
