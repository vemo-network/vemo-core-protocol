// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountV3.sol";
import "../../src/accounts/AccountProxy.sol";
import "../../src/VoucherFactory.sol";
import "../../src/helpers/NFTDescriptor/NFTDescriptor.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoVoucherFactorySC is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address walletFactoryProxy = vm.envAddress("VOUCHER_FACTORY_PROXY");
        address descriptorOwner = 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E;

        vm.startBroadcast(deployerPrivateKey);

        VoucherFactory implementation = new VoucherFactory();
        VoucherFactory proxy = VoucherFactory(payable(walletFactoryProxy));

        bytes memory data;
        proxy.upgradeToAndCall(address(implementation), data);
        
        // NFTDescriptor globalDescriptor = NFTDescriptor(Upgrades.deployUUPSProxy(
        //     "NFTDescriptor.sol",
        //     abi.encodeCall(
        //         NFTDescriptor.initialize,
        //         (descriptorOwner)
        //     )
        // ));

        // console.log("descriptor ", address(globalDescriptor));
        vm.stopBroadcast();
    }
}
