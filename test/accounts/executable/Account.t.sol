// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "erc6551/ERC6551Registry.sol";
import "erc6551/interfaces/IERC6551Account.sol";
import "erc6551/interfaces/IERC6551Executable.sol";

import "multicall-authenticated/Multicall3.sol";

import "../../../src/accounts/AccountV3Optimum.sol";
import "../../../src/accounts/AccountV3Upgradable.sol";
import "../../../src/AccountGuardian.sol";
import "../../../src/accounts/AccountProxy.sol";

import "./mocks/MockERC721.sol";
import "./mocks/MockSigner.sol";
import "./mocks/MockExecutor.sol";
import "./mocks/MockSandboxExecutor.sol";
import "./mocks/MockReverter.sol";
import "./mocks/MockAccountUpgradable.sol";

contract AccountTest is Test {
    Multicall3 forwarder;
    AccountV3Optimum implementation;
    AccountV3Upgradable upgradableImplementation;
    AccountProxy proxy;
    ERC6551Registry public registry;
    AccountGuardian public guardian;

    MockERC721 public tokenCollection;

    function setUp() public {
        registry = new ERC6551Registry();

        forwarder = new Multicall3();
        guardian = new AccountGuardian(address(this));
        implementation = new AccountV3Optimum(
            address(registry), address(guardian)
        );
        upgradableImplementation = new AccountV3Upgradable(
            address(registry), address(guardian)
        );
        proxy = new AccountProxy(address(guardian), address(upgradableImplementation));

        tokenCollection = new MockERC721();

        // mint tokenId 1 during setup for accurate cold call gas measurement
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        tokenCollection.mint(user1, tokenId);
    }

    function testNonOwnerCallsFail() public {
        uint256 tokenId = 1;
        address user2 = vm.addr(2);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        vm.deal(accountAddress, 1 ether);

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        // should fail if user2 tries to use account
        vm.prank(user2);
        vm.expectRevert(NotAuthorized.selector);
        account.execute(payable(user2), 0.1 ether, "", LibExecutor.OP_CALL);

        // should fail if user2 tries to use account
        vm.prank(user2);
        vm.expectRevert(NotAuthorized.selector);
        account.execute(payable(user2), 0.1 ether, "", LibExecutor.OP_CALL);
    }

    function testAccountOwnershipTransfer() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        vm.deal(accountAddress, 1 ether);

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        // should succeed with original owner
        vm.prank(user1);
        account.execute(payable(user1), 0.1 ether, "", LibExecutor.OP_CALL);

        // should fail if user2 tries to use account
        vm.prank(user2);
        vm.expectRevert(NotAuthorized.selector);
        account.execute(payable(user2), 0.1 ether, "", LibExecutor.OP_CALL);

        vm.prank(user1);
        tokenCollection.safeTransferFrom(user1, user2, tokenId);

        // should succeed now that user2 is owner
        vm.prank(user2);
        account.execute(payable(user2), 0.1 ether, "", LibExecutor.OP_CALL);

        assertEq(user2.balance, 0.1 ether);
    }

    function testSignatureVerification() public {
        uint256 tokenId = 1;

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        bytes32 hash = keccak256("This is a signed message");
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(1, hash);

        // ECDSA signature
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bytes4 returnValue = account.isValidSignature(hash, signature1);
        assertEq(returnValue, IERC1271.isValidSignature.selector);

        MockSigner mockSigner = new MockSigner();

        address[] memory callers = new address[](1);
        callers[0] = address(mockSigner);
        bool[] memory _permissions = new bool[](1);
        _permissions[0] = true;


        vm.prank(vm.addr(1));
        // Recursive account signature
        bytes memory recursiveSignature =
            abi.encodePacked(uint256(uint160(address(account))), uint256(65), uint8(0), signature1);
        returnValue = account.isValidSignature(hash, recursiveSignature);
        assertEq(returnValue, IERC1271.isValidSignature.selector);
    }

    function testSignatureVerificationFailsInvalidSigner() public {
        uint256 tokenId = 1;

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        bytes32 hash = keccak256("This is a signed message");

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(2, hash);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        bytes4 returnValue2 = account.isValidSignature(hash, signature2);

        assertFalse(returnValue2 == IERC1271.isValidSignature.selector);
    }

    function testExecuteCallRevert() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        vm.deal(accountAddress, 1 ether);

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        MockReverter mockReverter = new MockReverter();

        vm.prank(user1);
        vm.expectRevert(MockReverter.MockError.selector);
        account.execute(payable(address(mockReverter)), 0, abi.encodeWithSignature("fail()"), 0);
    }

    function testExecuteInvalidOperation() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        vm.deal(accountAddress, 1 ether);

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        vm.prank(user1);
        vm.expectRevert(InvalidOperation.selector);
        account.execute(vm.addr(2), 0.1 ether, "", type(uint8).max);
    }

    function testExecuteCreate() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        uint256 state = account.state();

        // should succeed when called by owner
        vm.prank(user1);
        bytes memory result = account.execute(address(0), 0, type(MockERC721).creationCode, 2);

        address deployedContract = address(uint160(uint256(bytes32(result)) >> 96));

        // batch execution should change state
        assertTrue(state != account.state());

        assertTrue(deployedContract.code.length > 0);

        // should fail when called by non-owner
        vm.prank(user2);
        vm.expectRevert(NotAuthorized.selector);
        account.execute(address(0), 0, type(MockERC721).creationCode, 2);
    }

    function testExecuteCreate2() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        address computedContract = Create2.computeAddress(
            keccak256("salt"), keccak256(type(MockERC721).creationCode), accountAddress
        );
        bytes memory payload = abi.encodePacked(keccak256("salt"), type(MockERC721).creationCode);

        uint256 state = account.state();

        // should succeed when called by owner
        vm.prank(user1);
        bytes memory result = account.execute(address(0), 0, payload, 3);

        address deployedContract = address(uint160(uint256(bytes32(result)) >> 96));

        // batch execution should change state
        assertTrue(state != account.state());

        assertEq(computedContract, deployedContract);
        assertTrue(deployedContract.code.length > 0);

        // should fail when called by non-owner
        vm.prank(user2);
        vm.expectRevert(NotAuthorized.selector);
        account.execute(address(0), 0, payload, 2);
    }

    function testAccountOwnerIsNullIfContextNotSet() public {
        address accountClone = Clones.clone(address(implementation));

        assertEq(AccountV3Optimum(payable(accountClone)).owner(), address(0));
    }

    function testEIP165Support() public {
        uint256 tokenId = 1;

        address accountAddress = registry.createAccount(
            address(implementation), 0, block.chainid, address(tokenCollection), tokenId
        );

        vm.deal(accountAddress, 1 ether);

        AccountV3Optimum account = AccountV3Optimum(payable(accountAddress));

        assertEq(account.supportsInterface(0x6faff5f1), true); // IERC6551Account
        assertEq(account.supportsInterface(0x51945447), true); // IERC6551Executable
        assertEq(account.supportsInterface(type(IERC1155Receiver).interfaceId), true);
        assertEq(account.supportsInterface(type(IERC165).interfaceId), true);
    }

    function testAccountUpgrade() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);

        address accountAddress = registry.createAccount(
            address(proxy), 0, block.chainid, address(tokenCollection), tokenId
        );

        AccountProxy(payable(accountAddress)).initialize(address(upgradableImplementation));
        AccountV3Upgradable account = AccountV3Upgradable(payable(accountAddress));

        MockAccountUpgradable upgradedImplementation = new MockAccountUpgradable(
            address(1),
            address(1),
            address(1),
            address(1)
        );

        vm.expectRevert(InvalidImplementation.selector);
        vm.prank(user1);
        bytes memory data;
        account.upgradeToAndCall(address(upgradedImplementation), data);

        guardian.setTrustedImplementation(address(upgradedImplementation), true);

        vm.prank(user1);
        account.upgradeToAndCall(address(upgradedImplementation), data);
        uint256 returnValue = MockAccountUpgradable(payable(accountAddress)).customFunction();

        assertEq(returnValue, 12345);
    }

    function testProxyZeroAddressInit() public {
        vm.expectRevert(InvalidImplementation.selector);
        new AccountProxy(address(1), address(0));
        vm.expectRevert(InvalidImplementation.selector);
        new AccountProxy(address(0), address(1));
    }
}