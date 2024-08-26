// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountV3.sol";
import "../../src/accounts/AccountProxy.sol";
import "../../src/VoucherFactory.sol";
import "../../src/helpers/NFTDescriptor/VoucherURI/NFTDescriptor.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoVoucherFactorySC is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address descriptorProxy = vm.envAddress("DESCRIPTOR_PROXY");
        vm.startBroadcast(deployerPrivateKey);

        NFTDescriptor implementation = new NFTDescriptor();
        NFTDescriptor proxy = NFTDescriptor(payable(descriptorProxy));

        bytes memory data;
        proxy.upgradeToAndCall(address(implementation), data);
        
        vm.stopBroadcast();
    }
}
