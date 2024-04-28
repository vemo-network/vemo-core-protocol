// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/AccountRegistry.sol";
import "src/VoucherAccount.sol";
import "src/VoucherFactory.sol";
import "src/DataRegistryV2.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployVemoSC is Script {
    // bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 constant WRITER_ROLE = keccak256("WRITER_ROLE"); // 0x2b8f168f361ac1393a163ed4adfa899a87be7b7c71645167bdaddd822ae453c8
    // bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    function run() public {
        vm.startBroadcast();
        // USDT 0x21b2E6c9805871743aeAD44c65bAb6cb9F0f1c60
        // USDC 0x38BE5E3f75C7D5F67558FC47c75c010783a28Cc9
        // ERC6551Registry registry = new ERC6551Registry(); // 0xa3937233d889c16d032fCaec16B3EE2690E2CE1A
        VoucherAccount accountImpl = new VoucherAccount(); // 0xab2d1385c3c0a9c4A8ec27b2Dc0942B9372341Cb
        // address factoryAddress = 0xf4943e8cC945071C778EE25ad0BE5857eD638556;
        // DataRegistryV2 dataRegistry = new DataRegistryV2(); // 0x82326364F9E9f200C4d52b703F141E099eB5C86F
        // dataRegistry.initialize(
        //     0xd71ff475af81442AFe5288D45AE5E790c4828b75,
        //     factoryAddress,
        //     "",
        //     DataRegistrySettings({
        //         disableComposable: true,
        //         disableDerivable: true
        //     })
        // );
        address proxy = Upgrades.deployUUPSProxy(
            "VoucherFactory.sol",
            abi.encodeCall(
                VoucherFactory.initialize,
                (
                    0xd71ff475af81442AFe5288D45AE5E790c4828b75,
                    0xf4943e8cC945071C778EE25ad0BE5857eD638556,
                    0x82326364F9E9f200C4d52b703F141E099eB5C86F,
                    0xa3937233d889c16d032fCaec16B3EE2690E2CE1A,
                    0xab2d1385c3c0a9c4A8ec27b2Dc0942B9372341Cb
                )
            )
        ); // proxy 0xD8DC465E853e8b7ce90482e322589EAf2052762C, impl 0xdb61bb3B89de1B4a497c59155Cb5E30933D1Cb04
        // dataRegistry.grantRole(DEFAULT_ADMIN_ROLE, proxy);
        // dataRegistry.grantRole(WRITER_ROLE, proxy);
        vm.stopBroadcast();
    }
}
