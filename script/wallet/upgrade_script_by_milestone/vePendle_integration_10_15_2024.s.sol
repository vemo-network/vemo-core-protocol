
/**
 *  forge script script/Deploy.s.sol --rpc-url https://avalanche.drpc.org --private-key private_key  --broadcast  --verify --chain-id 43114 --ffi --etherscan-api-key 

 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import "forge-std/Script.sol";
import "../../../src/AccountRegistry.sol";
import "../../../src/AccountGuardian.sol";
import "../../../src/accounts/NFTAccountDelegable.sol";
import "../../../src/accounts/AccountProxy.sol";
import {WalletFactory} from "../../../src/WalletFactory.sol";
import "../UUPSProxy.sol";
import {CollectionDeployer} from "../../../src/CollectionDeployer.sol";
import "multicall-authenticated/Multicall3.sol";
import {ERC6551Registry} from "erc6551/ERC6551Registry.sol";
import {NFTDelegationDescriptor} from "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {NFTAccountDescriptor} from "../../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {VeTerm} from "../../../src/terms/VeTerm.sol";

/**
  walletfactory address: 0x2D675d0C90D39751FA33d7b2498D556142590a36 
  WalletFactory Proxy address: 0x5A72A673f0621dC3b39B59084a72b95706E75EFd 

  guardian  0xC833002b8179716Ae225B7a2B3DA463C47B14F76
  account v3  0xA94e04f900eF10670F0D730A49cEA5447fe6fcb8
  accountProxy  0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73
  account registry  0x000000006551c19487814612e58FE06813775758
  wallet factory proxy  0x5A72A673f0621dC3b39B59084a72b95706E75EFd

  ------------ ARB
  walletfactory address: 0x2D675d0C90D39751FA33d7b2498D556142590a36 
  WalletFactory Proxy address: 0x5A72A673f0621dC3b39B59084a72b95706E75EFd 
  guardian  0xC833002b8179716Ae225B7a2B3DA463C47B14F76
  account v3  0xcb4a7FF79E90BDE163583f20BB96E8610b0b5829
  accountProxy  0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73
  account registry  0x000000006551c19487814612e58FE06813775758
  wallet factory proxy  0x5A72A673f0621dC3b39B59084a72b95706E75EFd

  collectionDeployer  0xa9457218CeD3Dcdd2ab54dFAe020b32da9480A19
  vemoNFTdescriptor  0x92C301E70Ee2062960D6A8456ea9f340AD2F79a9
  term  0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7
  descriptor  0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B
  vemoCollection  0xa815Fd40821b722765Daa326177E3832703C390f
  vePendle voter  0xe199E125a3cCA16A688D964C555b457Bdf7C6125

 */

/**
 * Ethereum deployment 
 * walletfactory upgrade to implementation: 0x2e68609AfDFCEEd1A901A5832860c22277D2aAbd 

  account v3 upgraded to  0x42ea7f52E9D80637eB05a1Df4b067A182bD31AB5
  CollectionDeployer is set to WalletFatory  0xa9457218CeD3Dcdd2ab54dFAe020b32da9480A19
  vemoNFTdescriptor  0x2a5782937c1ffDBe22a8f1236c730f6f6a84908E
  vemoCollection  0x7aBD3fb92c722659CAf9A9692e94BcAA651F9759
  vePendle voter  0x90ba36e80bEAB9F32b81AE3E37A5Cc89BEfCd118
  term  0x3dA87E0397acca76a7F21C6ceC1E61B576343a31
  descriptor  0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7 // ???
 */

struct VeBalance {
    uint128 bias;
    uint128 slope;
}

struct UserPoolData {
    uint64 weight;
    VeBalance vote;
}
interface IPendleVoting {
    function vote(address[] memory pools, uint64[] memory weights) external; // total weights  = 1e18
    function getUserPoolVote(address user, address pool) external view returns (UserPoolData memory);
}

interface IPendleGaugeController {
}

interface IPendleRewardManager {
    function claimRetail(
        address receiver,
        uint256 totalAccrued,
        bytes32[] calldata proof
    ) external returns (uint256 amountOut);
}

contract DeployVemoWalletSC is Script {
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

    // latest collection using till October
    address NFTCollectionAddress = 0x7aBD3fb92c722659CAf9A9692e94BcAA651F9759;

    // entrypoint for ERC4337, if there is no erc4337 protocol, leave it zero
    address entrypointERC4337 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    uint160 vemoCollectionIndex = 123456; // current using on production

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        WalletFactory _walletFactory = WalletFactory(payable(walletFactoryProxy));

        /**
         * Deploy new VemoWallet implementation
         */
        AccountGuardian guardian = AccountGuardian(guardianAddress);
        NFTAccountDelegable accountv3Implementation = new NFTAccountDelegable(
            address(forwarder), address(registry), address(guardian)
        );

        // whitelist new implementation
        guardian.setTrustedImplementation(address(accountv3Implementation), true);
        _walletFactory.setWalletImpl(address(accountv3Implementation));

        console2.log("account v3 upgraded to ", address(accountv3Implementation));

        /**
         * deploy new components for role module including
         * 1. collection deployer
         * 2. NFT delegation descriptor
         * 3. vependleterm
         * 4. NFT delegation collection
         * */
        deployVemoRoleModule(_walletFactory, guardian);

        vm.stopBroadcast();
    }

    function deployVemoRoleModule(WalletFactory proxy, AccountGuardian guardian) public {
        // Deploy collection deployer
        CollectionDeployer collectionDeployer = new CollectionDeployer{salt: bytes32(salt)}(walletFactoryProxy);
        proxy.setCollectionDeployer(address(collectionDeployer));
        console.log("CollectionDeployer is set to WalletFatory ", address(collectionDeployer));

        // // deploy a new  descriptor
        // address descriptor = Upgrades.deployUUPSProxy(
        //     "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
        //     abi.encodeCall(
        //         NFTDelegationDescriptor.initialize,
        //         owner
        //     )
        // );

        // deploy a new term
        address term = Upgrades.deployUUPSProxy(
            "VeTerm.sol:VeTerm",
            abi.encodeCall(
                VeTerm.initialize,
                (
                    owner,
                    address(proxy),
                    address(guardian)
                )
            )
        );
        setVePendleProperties(VeTerm(payable(term)));

        //term  0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7
        //descriptor  0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B
        address _descriptorEther = 0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7;
        address nftDlgAddress = proxy.createDelegateCollection(
            "vePENDLE Voter Ethereum",
            "VPV",
            _descriptorEther, 
            term,
            NFTCollectionAddress
        );

        console.log("vePendle voter nft collection ", nftDlgAddress);
        console.log("term ", term);
        console.log("descriptor ", _descriptorEther);
    }

    function setVePendleProperties(VeTerm term) public {
        IPendleVoting PENDLE_VOTING = IPendleVoting(0x44087E105137a5095c008AaB6a6530182821F2F0);
        IPendleRewardManager REWARD_MANAGER = IPendleRewardManager(0x8C237520a8E14D658170A633D96F8e80764433b9);
        
        address[] memory whitelist = new address[](2);
        bytes4[] memory selectors = new bytes4[](2);
        bytes4[] memory _harvestSelectors = new bytes4[](1);

        bytes24[] memory actions = new bytes24[](2);
        bytes24[] memory _harvestActions = new bytes24[](1);
        
        // allow calling those methods
        selectors[0] = PENDLE_VOTING.vote.selector;
        selectors[1] = IPendleRewardManager.claimRetail.selector;
        _harvestSelectors[0] = IPendleRewardManager.claimRetail.selector;

        // allow calling to pendle voting and reward manager
        whitelist[0] = address(PENDLE_VOTING);
        whitelist[1] = address(REWARD_MANAGER);

        // reward is eth
        address[] memory _rewardAssets_ = new address[](1);
        _rewardAssets_[0] = address(0);

        actions[0] = bytes24(abi.encodePacked(selectors[0], whitelist[0]));
        actions[1] = bytes24(abi.encodePacked(selectors[1], whitelist[1]));
        _harvestActions[0] = bytes24(abi.encodePacked(_harvestSelectors[1], whitelist[1]));

        term.setTermProperties(actions, _harvestActions, _rewardAssets_ );
    }

    function upgradeTermInterface() public {

    }
    
}
