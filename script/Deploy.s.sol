
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AccountRegistry.sol";
import "../src/VoucherAccount.sol";
import "../src/VoucherFactory.sol";
import "../src/DataRegistryV2.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoSC is Script {
  
    function run() public {
        vm.startBroadcast();
        VoucherAccount accountImpl = new VoucherAccount();
        vm.stopBroadcast();
    }
}
