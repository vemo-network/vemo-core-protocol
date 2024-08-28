// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "erc6551/ERC6551Registry.sol";
import "erc6551/interfaces/IERC6551Account.sol";
import "erc6551/interfaces/IERC6551Executable.sol";

import "multicall-authenticated/Multicall3.sol";

import "../../../src/accounts/VemoWalletV3Upgradable.sol";
import "../../../src/AccountGuardian.sol";
import "../../../src/accounts/AccountProxy.sol";
import "../../../src/CollectionDeployer.sol";
import "../../../src/helpers/VemoDelegationCollection.sol";

import "../../mock/USDT.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockSigner.sol";
import "./mocks/MockExecutor.sol";
import "./mocks/MockSandboxExecutor.sol";
import "./mocks/MockReverter.sol";
import "./mocks/MockAccountUpgradable.sol";
import {WalletFactory} from "../../../src/WalletFactory.sol";
import {NFTDelegationDescriptor} from "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {VePendleTerm} from "../../../src/terms/VePendleTerm.sol";

contract DelegationCollectionTest is Test {
    Multicall3 forwarder;
    VemoWalletV3Upgradable upgradableImplementation;
    AccountProxy proxy;
    ERC6551Registry public registry;
    AccountGuardian public guardian;
    WalletFactory walletFactory;
    MockERC721 public tokenCollection;

    uint256 defaultAdminPrivateKey = 1;
    uint256 userPrivateKey = 2;
    uint256 feeReceiverPrivateKey = 3;
    address defaultAdmin = vm.addr(defaultAdminPrivateKey);
    address user = vm.addr(userPrivateKey);
    address user1 = vm.addr(userPrivateKey+1);
    address userReceiver = vm.addr(userPrivateKey+99);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);
    NFTDelegationDescriptor descriptor;
    VePendleTerm term;

    CollectionDeployer collectionDeployer;
    USDT usdt = new USDT();

    function setUp() public {
        vm.deal(user, 1 ether);
        vm.deal(user1, 1 ether);

        registry = new ERC6551Registry();

        forwarder = new Multicall3();
        guardian = new AccountGuardian(address(this));
        upgradableImplementation = new VemoWalletV3Upgradable(
            address(1), address(forwarder), address(registry), address(guardian)
        );
        proxy = new AccountProxy(address(guardian), address(upgradableImplementation));

        tokenCollection = new MockERC721();

        guardian.setTrustedImplementation(address(upgradableImplementation), true);
        address walletProxy = Upgrades.deployUUPSProxy(
            "WalletFactory.sol:WalletFactory",
            abi.encodeCall(
                WalletFactory.initialize,
                (defaultAdmin, address(registry), address(upgradableImplementation), address(upgradableImplementation))
            )
        );

        walletFactory = WalletFactory(payable(walletProxy));

        descriptor = NFTDelegationDescriptor(Upgrades.deployUUPSProxy(
            "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
            abi.encodeCall(
                NFTDelegationDescriptor.initialize,
                (address(this))
            )
        ));
        term = VePendleTerm(Upgrades.deployUUPSProxy(
            "VePendleTerm.sol:VePendleTerm",
            abi.encodeCall(
                VePendleTerm.initialize,
                (
                    address(this),
                    walletProxy,
                    address(guardian)
                )
            )
        ));

        guardian.setTrustedImplementation(address(term), true);

        collectionDeployer = new CollectionDeployer(walletProxy);

        vm.startPrank(defaultAdmin);
        walletFactory.setCollectionDeployer(address(collectionDeployer));
    }

    function testSimpleDelegate() public {
        vm.startPrank(defaultAdmin);
        address nftAddress = walletFactory.createWalletCollection(
            uint160(address(usdt)),
            "walletfactory",
            "walletfactory",
            "walletfactory"
        );
        
        (uint256 tokenId, address _tba) = walletFactory.create(nftAddress, "");

        // create delegate collection
        address dlgCollection = walletFactory.createDelegateCollection(
            "A",
            "A1",
            address(descriptor), 
            address(term),
            nftAddress
        );

        assertEq(
            MockERC721(dlgCollection).name(),
            "A"
        );

        assertEq(
            MockERC721(dlgCollection).symbol(),
            "A1"
        );

        assertEq(
            VemoDelegationCollection(dlgCollection).term(),
            address(term)
        );

       assertEq(
            VemoDelegationCollection(dlgCollection).issuer(),
            address(nftAddress)
        );

        vm.expectRevert();
        walletFactory.createDelegateCollection(
            "A",
            "A",
            address(descriptor), 
            address(term),
            nftAddress
        );

        // mint a derivative nft of that TBA
        VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);

        vm.expectRevert();
        VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);
        assertEq(defaultAdmin, MockERC721(dlgCollection).ownerOf(tokenId));
    }

    function testDelegateFail() public {
        vm.startPrank(defaultAdmin);
        address nftAddress = walletFactory.createWalletCollection(
            uint160(address(usdt)),
            "walletfactory",
            "walletfactory",
            "walletfactory"
        );
        
        (uint256 tokenId, address _tba) = walletFactory.create(nftAddress, "");

        // create delegate collection
        address dlgCollection = walletFactory.createDelegateCollection(
            "A",
            "A1",
            address(descriptor), 
            address(term),
            nftAddress
        );

        // mint a derivative nft of that TBA
        VemoDelegationCollection(dlgCollection).delegate(tokenId, user);
        assertEq(user, MockERC721(dlgCollection).ownerOf(tokenId));

        vm.startPrank(user);
        // allow tranfer if there is no revoking
        MockERC721(dlgCollection).transferFrom(user, user1, tokenId);

        vm.startPrank(user1);
        MockERC721(dlgCollection).transferFrom(user1, user, tokenId);

        //revoke only trigger by the TBA owner
        vm.startPrank(defaultAdmin);
        VemoDelegationCollection(dlgCollection).revoke(tokenId);
        console.log(
            VemoDelegationCollection(dlgCollection).revokingRoles(tokenId)
        );
        console.log("block.timestamp ", block.timestamp);
        skip(100);
        console.log("block.timestamp 1", block.timestamp);

        // revert in duration time
        vm.startPrank(user);
        vm.expectRevert();
        MockERC721(dlgCollection).transferFrom(user, user1, tokenId);
        
        vm.startPrank(defaultAdmin);
        vm.expectRevert();
        VemoDelegationCollection(dlgCollection).burn(tokenId);

        skip(9999999);

        vm.startPrank(user);
        vm.expectRevert();
        MockERC721(dlgCollection).transferFrom(user, user1, tokenId);

        vm.startPrank(defaultAdmin);
        VemoDelegationCollection(dlgCollection).burn(tokenId);

        // no longer exist
        vm.expectRevert();
        MockERC721(dlgCollection).ownerOf(tokenId);
    }
}