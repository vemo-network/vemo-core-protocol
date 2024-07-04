// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountV3.sol";
import "../../src/WalletFactory.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoWalletWithTokenboundFoundationSC is Script {
    struct DeployedAddresses {
        address create2_factory;
        address erc6551_registry;
        address account_proxy;
        address account_implementation;
        address account_guardian;
        address authenticated_multicall;
        address layerzero_executor;
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/wallet/tokenbound.foundation.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        DeployedAddresses memory deployedAddresses = abi.decode(data, (DeployedAddresses));

        Upgrades.deployUUPSProxy(
            "WalletFactory.sol",
            abi.encodeCall(
                WalletFactory.initialize,
                (
                    vm.addr(deployerPrivateKey),
                    deployedAddresses.erc6551_registry,
                    deployedAddresses.account_proxy,
                    deployedAddresses.account_implementation
                )
            )
        );

        vm.stopBroadcast();
    }
}
