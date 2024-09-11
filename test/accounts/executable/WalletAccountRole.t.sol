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

import "../../../src/accounts/NFTAccountDelegable.sol";
import "../../../src/AccountGuardian.sol";
import "../../../src/accounts/AccountProxy.sol";
import {CollectionDeployer} from "../../../src/CollectionDeployer.sol";
import {VemoDelegationCollection} from "../../../src/helpers/VemoDelegationCollection.sol";

import "../../mock/USDT.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockSigner.sol";
import "./mocks/MockExecutor.sol";
import "./mocks/MockSandboxExecutor.sol";
import "./mocks/MockReverter.sol";
import "./mocks/MockVePendle.sol";
import "./mocks/MockAccountUpgradable.sol";
import {WalletFactory} from "../../../src/WalletFactory.sol";
import {NFTDelegationDescriptor} from "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {NFTAccountDescriptor} from "../../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";
import {VePendleTerm} from "../../../src/terms/VePendleTerm.sol";

contract AccountRoleTest is Test {
    Multicall3 forwarder;
    NFTAccountDelegable upgradableImplementation;
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
    NFTAccountDescriptor vemoCollectionDescriptor;
    VePendleTerm term;

    CollectionDeployer collectionDeployer;
    USDT usdt = new USDT();
    MockVePendle pendle = new MockVePendle();

    function setUp() public {
        registry = new ERC6551Registry();

        forwarder = new Multicall3();
        guardian = new AccountGuardian(address(this));
        upgradableImplementation = new NFTAccountDelegable(
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

        vemoCollectionDescriptor = NFTAccountDescriptor(Upgrades.deployUUPSProxy(
            "NFTAccountDescriptor.sol:NFTAccountDescriptor",
            abi.encodeCall(
                NFTAccountDescriptor.initialize,
                (address(this))
            )
        ));

        term = VePendleTerm(payable(Upgrades.deployUUPSProxy(
            "VePendleTerm.sol:VePendleTerm",
            abi.encodeCall(
                VePendleTerm.initialize,
                (
                    address(this),
                    walletProxy,
                    address(guardian)
                )
            )
        )));

        guardian.setTrustedImplementation(address(term), true);

        collectionDeployer = new CollectionDeployer(walletProxy);

        // init vePendle term and mock pendle reward
        vm.deal(address(pendle), 1 ether);

        bytes4[] memory selectors;
        bytes4[] memory _harvestSelectors = new bytes4[](1);
        _harvestSelectors[0] = pendle.claim.selector;
        address[] memory _whitelist;
        address[] memory _rewardAssets_ = new address[](1);
        _rewardAssets_[0] = address(0);

        term.setTermProperties(
            address(0x0),
            selectors,
            _harvestSelectors,
            _whitelist,
            _rewardAssets_
        );
        

        vm.startPrank(defaultAdmin);
        walletFactory.setCollectionDeployer(address(collectionDeployer));

    }

    function testMintNFTDelegation() public {
        vm.startPrank(defaultAdmin);
        address nftAddress = walletFactory.createWalletCollection(
            uint160(address(usdt)),
            "walletfactory",
            "walletfactory",
            address(vemoCollectionDescriptor)
        );
        
        (uint256 tokenId, address _tba) = walletFactory.create(nftAddress);

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
        NFTAccountDelegable(payable(_tba)).delegate(dlgCollection, defaultAdmin);

        vm.expectRevert();
        NFTAccountDelegable(payable(_tba)).delegate(dlgCollection, defaultAdmin);

        assertEq(defaultAdmin, MockERC721(dlgCollection).ownerOf(tokenId));

        // transfer the derivative nft
        MockERC721(dlgCollection).transferFrom(defaultAdmin, user, tokenId);

        vm.deal(_tba, 1 ether);

        // check the the owner of derivative nft is valid signer
        vm.startPrank(user);
        vm.expectRevert(NotAuthorized.selector);
        NFTAccountDelegable(payable(_tba)).execute(vm.addr(2), 0.1 ether, "", 0);

        assertEq(_tba.balance, 1 ether);
        NFTAccountDelegable(payable(_tba)).delegateExecute(dlgCollection, vm.addr(2), 0.1 ether, "", "");
        assertEq(_tba.balance, 1 ether - 0.1 ether);
        assertEq(vm.addr(2).balance, 0.1 ether);

        // verify signature
        bytes32 hash = keccak256("This is a signed message");
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(2, hash);

        // ECDSA signature
        bytes memory signature1 = abi.encodePacked(r1, s1, v1, dlgCollection, new bytes(64));
        bytes4 returnValue = NFTAccountDelegable(payable(_tba)).isValidSignature(hash, signature1);

        vm.stopPrank();
    }

    function testHarvestDistribution() public {
        vm.startPrank(defaultAdmin);
        address nftAddress = walletFactory.createWalletCollection(
            uint160(address(usdt)),
            "walletfactory",
            "walletfactory",
            address(vemoCollectionDescriptor)
        );
        
        (uint256 tokenId, address _tba) = walletFactory.create(nftAddress);

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
        NFTAccountDelegable(payable(_tba)).delegate(dlgCollection, defaultAdmin);
        // VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);

        vm.expectRevert();
        NFTAccountDelegable(payable(_tba)).delegate(dlgCollection, defaultAdmin);
        // VemoDelegationCollection(dlgCollection).delegate(tokenId, defaultAdmin);

        assertEq(defaultAdmin, MockERC721(dlgCollection).ownerOf(tokenId));

        // transfer the derivative nft
        MockERC721(dlgCollection).transferFrom(defaultAdmin, user, tokenId);

        vm.startPrank(user);
        
        NFTAccountDelegable(payable(_tba)).delegateExecute(
            dlgCollection,
            address(pendle),
            0,
            abi.encodeWithSignature(
                "claim()"
            ),
            ""
        );

        uint16 splitRatio = 1; // 0.01%
        uint256 rewardAmount = 1 ether;
        
        assertEq(address(user).balance, 1 ether / 10000);
        assertEq(address(_tba).balance, 1 ether -  (1 ether / 10000));
    }
}