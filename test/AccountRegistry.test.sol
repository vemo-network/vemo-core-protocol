pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/AccountRegistry.sol";
import "./mock/NFT.sol";
import "../src/VoucherAccount.sol";

import "../src/interfaces/IERC6551Executable.sol";

contract RegistryTest is Test {
    AccountRegistry public registry;
    VoucherAccount public implementation;

    event VoucherAccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    function setUp() public {
        registry = new AccountRegistry();
        implementation = new VoucherAccount();

        // Ensure interface IDs don't unexpectedly change
        assertEq(type(IVoucherAccount).interfaceId, bytes4(0x05db6c7e));
        assertEq(type(IERC6551Executable).interfaceId, bytes4(0x51945447));
    }

    function testDeploy() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        bytes32 salt = bytes32(uint256(400));
        bytes memory initData;

        // initData is mandatory with Vemo ecosystem
        address deployedAccount =
            registry.createAccount(address(implementation), salt, chainId, tokenAddress, tokenId, initData);

        address registryComputedAddress =
            registry.account(address(implementation), salt, chainId, tokenAddress, tokenId);

        assertEq(deployedAccount, registryComputedAddress);
    }

    function testDeploy2() public {
        uint256 chainId = 100;
        address tokenAddress = address(200);
        uint256 tokenId = 300;
        bytes32 salt = bytes32(uint256(400));
        bytes memory initData;

        address account = registry.account(address(implementation), salt, chainId, tokenAddress, tokenId);

        vm.expectEmit(true, true, true, true);
        emit VoucherAccountCreated(account, address(implementation), salt, chainId, tokenAddress, tokenId);

        address deployedAccount =
            registry.createAccount(address(implementation), salt, chainId, tokenAddress, tokenId, initData);
        assertEq(deployedAccount, account);

        deployedAccount =
            registry.createAccount(address(implementation), salt, chainId, tokenAddress, tokenId, initData);
        assertEq(deployedAccount, account);
    }

    function testDeployFuzz(
        address _implementation,
        uint256 chainId,
        address tokenAddress,
        uint256 tokenId,
        bytes32 salt
    ) public {
        address account = registry.account(_implementation, salt, chainId, tokenAddress, tokenId);
        bytes memory initData;

        address deployedAccount =
            registry.createAccount(_implementation, salt, chainId, tokenAddress, tokenId, initData);

        assertEq(deployedAccount, account);
    }
}
