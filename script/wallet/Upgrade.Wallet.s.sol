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
        address walletFactoryProxy = vm.envAddress("WALLET_FACTORY_PROXY");

        vm.startBroadcast(deployerPrivateKey);

        WalletFactory implementation = new WalletFactory();
        WalletFactory proxy = WalletFactory(payable(walletFactoryProxy));

        bytes memory data;
        proxy.upgradeToAndCall(address(implementation), data);
        
        proxy.setFeeReceiver(address(0x79ef006E9069b0c45b6b8DD7b8809AaDffce1881));
        proxy.setFee(1, 0);

        // console.logAddress(address(implementation));
        vm.stopBroadcast();
    }
}
