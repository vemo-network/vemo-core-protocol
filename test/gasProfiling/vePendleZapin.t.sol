
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../src/zapper/vePendleZapIn.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "multicall-authenticated/Multicall3.sol";
import {NFTAccountDelegable} from "../../src/accounts/NFTAccountDelegable.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountProxy.sol";
import {CollectionDeployer} from "../../src/CollectionDeployer.sol";
import {VemoDelegationCollection} from "../../src/helpers/VemoDelegationCollection.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "erc6551/ERC6551Registry.sol";
import "../accounts/executable/mocks/MockERC721.sol";
import {WalletFactory} from "../../src/WalletFactory.sol";
import {NFTDelegationDescriptor} from "../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {NFTAccountDescriptor} from "../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract PendleZapinTest is Test, IERC721Receiver {
    bytes32 salt = bytes32(0x12341e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c);
    vePendleZapIn zapin;
    bool public isForkEnabled;

    address user = vm.addr(22);
    address user1 = vm.addr(23);
    address delegatee = vm.addr(24);

    //// Vemo setup
    Multicall3 forwarder = Multicall3(0x560123E26A057A3e1006d17091a0e82855Ec52b8);
    NFTAccountDelegable upgradableImplementation;
    AccountProxy proxy;
    ERC6551Registry public registry;
    AccountGuardian public guardian;
    WalletFactory walletFactory;

    address defaultAdmin = vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
    NFTDelegationDescriptor delegationDescriptor;
    NFTAccountDescriptor vemoCollectionDescriptor;

    CollectionDeployer collectionDeployer = CollectionDeployer(0x84F27Ab1722BCA7D0B0D9944E2ADFB451Baeb0a9);
    
    address globalTba;
    address NFTAccountCollection;
    address dlgCollection;
    address delegateCollection;
    uint256 constant PROPOSAL_ID = 1;
    address constant GAUGE_ADDRESS = 0xC374f7eC85F8C7DE3207a10bB1978bA104bdA3B2;

    function setUp() public {
        isForkEnabled = vm.envOr("LOCAL_FORK_ENABLED", false);

        if (isForkEnabled) {
            vm.createSelectFork("http://127.0.0.1:8545");
            deployVemoSystem();
        }
    }

    function deployVemoSystem() public {
        vm.startPrank(defaultAdmin);
        registry = new ERC6551Registry{salt: salt}();
        guardian = new AccountGuardian{salt: salt}(defaultAdmin);
        upgradableImplementation = new NFTAccountDelegable{salt: salt}(
            address(forwarder), address(registry), address(guardian)
        );
        proxy = new AccountProxy{salt: salt}(address(guardian), address(upgradableImplementation));

        guardian.setTrustedImplementation(address(upgradableImplementation), true);

        address walletProxy = Upgrades.deployUUPSProxy(
            "WalletFactory.sol:WalletFactory",
            abi.encodeCall(
                WalletFactory.initialize,
                (defaultAdmin, address(registry), address(upgradableImplementation), address(upgradableImplementation))
            )
        );

        walletFactory = WalletFactory(payable(walletProxy));

        delegationDescriptor = NFTDelegationDescriptor(Upgrades.deployUUPSProxy(
            "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
            abi.encodeCall(
                NFTDelegationDescriptor.initialize,
                (defaultAdmin)
            )
        ));

        vemoCollectionDescriptor = NFTAccountDescriptor(Upgrades.deployUUPSProxy(
            "NFTAccountDescriptor.sol:NFTAccountDescriptor",
            abi.encodeCall(
                NFTAccountDescriptor.initialize,
                (defaultAdmin)
            )
        ));

        collectionDeployer = new CollectionDeployer{salt: salt}(walletProxy);
        walletFactory.setCollectionDeployer(address(collectionDeployer));

        NFTAccountCollection = walletFactory.createWalletCollection(
            1,
            "walletfactory1",
            "walletfactory1",
            address(vemoCollectionDescriptor)
        );

        delegateCollection = walletFactory.createDelegateCollection(
            "A",
            "B",
            address(delegationDescriptor),
            address(0x0),
            NFTAccountCollection
        );

        zapin = vePendleZapIn(payable(Upgrades.deployUUPSProxy(
            "vePendleZapIn.sol:vePendleZapIn",
            abi.encodeCall(
                vePendleZapIn.initialize,
                (
                    defaultAdmin,
                    walletProxy,
                    delegatee
                )
            )
        )));
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function testZapin() public {
        vm.startPrank(user);

        uint256 depositAmount = 1 ether;
        uint128 newExpiry = 1788998400;

        deal(address(zapin.PENDLE()), user, 10 ether);
        
        zapin.PENDLE().approve(address(zapin), depositAmount);
        uint256[] memory chains = new uint256[](0);
        (uint256 tokenId, address tba) = zapin.zapInAndBroadcast(NFTAccountCollection, delegateCollection, depositAmount, newExpiry, chains);

        assertTrue(ERC721(NFTAccountCollection).ownerOf(tokenId) == user, "nft is never transfer to end user");
        assertTrue(ERC721(delegateCollection).ownerOf(tokenId) == zapin.vemoDelegatee(), "nft is never transfer to end user");
        assertTrue(
            zapin.VE_PENDLE().balanceOf(tba) > 0, " vependle should large than zero"
        );
    }

    function testZapinAndBroadcast() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1 ether;
        uint128 newExpiry = 1788998400;

        deal(address(zapin.PENDLE()), user1, 10 ether);
        
        zapin.PENDLE().approve(address(zapin), depositAmount);
        uint256[] memory chains = new uint256[](1);
        chains[0] = 42161;
        (uint256 tokenId, address tba) = zapin.zapInAndBroadcast(NFTAccountCollection, delegateCollection, depositAmount, newExpiry, chains);

        assertTrue(ERC721(NFTAccountCollection).ownerOf(tokenId) == user1, "nft is never transfer to end user");
        assertTrue(ERC721(delegateCollection).ownerOf(tokenId) == zapin.vemoDelegatee(), "nft is never transfer to end user");
        assertTrue(
            zapin.VE_PENDLE().balanceOf(tba) > 0, " vependle should large than zero"
        );
    }
}