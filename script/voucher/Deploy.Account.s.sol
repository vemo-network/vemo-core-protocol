
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/accounts/VoucherAccount.sol";
import "../../src/VoucherFactory.sol";
import "@openzeppelin/contracts/interfaces/IERC1967.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

interface ITransparentUpgradeableProxy is IERC1967 {
    function upgradeToAndCall(address, bytes calldata) external payable;
}
contract DeployVemoSC is Script {
  
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        VoucherAccount newImplementation = new VoucherAccount();

        vm.stopBroadcast();
    }
}

