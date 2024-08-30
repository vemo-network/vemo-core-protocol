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

contract AccountRoleTest is Test {
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
    address user1 = vm.addr(userPrivateKey + 1);
    address userReceiver = vm.addr(userPrivateKey+99);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);
    NFTDelegationDescriptor descriptor;
    VePendleTerm term;

    CollectionDeployer collectionDeployer;
    USDT usdt = new USDT();

    function setUp() public {
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

    function testMintNFTDelegation() public {
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
        
        vm.stopPrank();

        guardian.setTrustedImplementation(address(dlgCollection), true);

        vm.startPrank(defaultAdmin);
        vm.expectRevert();
        walletFactory.createDelegateCollection(
            "A",
            "A",
            address(descriptor), 
            address(term),
            nftAddress
        );

        // // mint a derivative nft of that TBA
        VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);

        vm.expectRevert();
        VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);
        VemoWalletV3Upgradable(payable(_tba)).setDelegate(dlgCollection);

        assertEq(
            VemoWalletV3Upgradable(payable(_tba)).getDelegate(),
            dlgCollection
        );

        assertEq(defaultAdmin, MockERC721(dlgCollection).ownerOf(tokenId));

        // transfer the derivative nft
        MockERC721(dlgCollection).transferFrom(defaultAdmin, user, tokenId);

        vm.deal(_tba, 1 ether);

        // check the the owner of derivative nft is valid signer
        vm.startPrank(user);
        vm.expectRevert(NotAuthorized.selector);
        VemoWalletV3Upgradable(payable(_tba)).execute(vm.addr(2), 0.1 ether, "", 0);

        VemoWalletV3Upgradable(payable(_tba)).delegateExecute(dlgCollection, vm.addr(2), 0.1 ether, "", 0);

        VemoWalletV3Upgradable(payable(_tba)).isValidSigner(user, "");

        // check if the owneer of the derivative nft is executable
        assertTrue(
            VemoWalletV3Upgradable(payable(_tba)).isValidSigner(defaultAdmin, "") == IERC6551Account.isValidSigner.selector
        );

        assertTrue(
            VemoWalletV3Upgradable(payable(_tba)).isValidSigner(user, "") == IERC6551Account.isValidSigner.selector
        );

        vm.startPrank(user);
        bytes32 hash = keccak256("This is a signed message");
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(2, hash);

        // ECDSA signature
        bytes memory signature1 = abi.encodePacked(r1, s1, v1, dlgCollection, new bytes(64));

        console.log("signature1.length ", signature1.length);
        bytes4 returnValue = VemoWalletV3Upgradable(payable(_tba)).isValidSignature(hash, signature1);
        assertEq(returnValue, IERC1271.isValidSignature.selector);
        vm.stopPrank();

        // vm.startPrank(user1);
        // hash = keccak256("This is a signed message 111");
        // ( v1, r1, s1) = vm.sign(3, hash);

        // // ECDSA signature
        // bytes memory signature2 = abi.encodePacked(r1, s1, v1);
        // returnValue = VemoWalletV3Upgradable(payable(_tba)).isValidSignature(hash, signature2);
        // assertEq(returnValue != IERC1271.isValidSignature.selector, true);

    }
}