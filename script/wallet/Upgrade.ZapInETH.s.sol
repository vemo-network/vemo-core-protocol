
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../src/AccountRegistry.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/NFTAccountDelegable.sol";
import "../../src/accounts/AccountProxy.sol";
import {WalletFactory} from "../../src/WalletFactory.sol";
import "./UUPSProxy.sol";
import {CollectionDeployer} from "../../src/CollectionDeployer.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {vePendleZapIn} from "../../src/zapper/vePendleZapIn.sol";

interface IPendleRewardManager {
    function claimRetail(
        address receiver,
        uint256 totalAccrued,
        bytes32[] calldata proof
    ) external returns (uint256 amountOut);
}

contract DeployZapperARB is Script {
    // a Prime
    uint256 salt = 0x8cb91e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c;

    /**
     * prod configuration
     */
                        
    address forwarder = 0xcA1167915584462449EE5b4Ea51c37fE81eCDCCD;
    address registry = 0x000000006551c19487814612e58FE06813775758;
    address owner = 0x308C6c08735c5cB323FC78b956Dcae19CC008608;
    address tokenboundLayerZero = 0x96f0445246B19Fa098f8bb4dfA907eD38F6155d5;
    address walletFactoryProxy = 0x5A72A673f0621dC3b39B59084a72b95706E75EFd;
    address guardianAddress = 0xC833002b8179716Ae225B7a2B3DA463C47B14F76;
    address accountProxyAddress = 0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73;

    address NFTCollectionAddress = 0xa815Fd40821b722765Daa326177E3832703C390f;
    address NFTDelegationCollection = 0x0cAcC8B55291aF4F8A8D9e300Fa67c74891D5884;

    // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
    address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        vePendleZapIn vetermImplementation = new vePendleZapIn{salt: bytes32(salt)}(walletFactoryProxy, owner);

        console.log("zapin vependle address proxy ", address(vetermImplementation));
        vm.stopBroadcast();
    }
    
}
