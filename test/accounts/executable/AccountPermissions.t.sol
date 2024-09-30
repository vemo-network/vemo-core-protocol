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

import "../../../src/accounts/AccountV3Optimum.sol";
import "../../../src/AccountGuardian.sol";
import "../../../src/accounts/AccountProxy.sol";

import "./mocks/MockERC721.sol";
import "./mocks/MockSigner.sol";
import "./mocks/MockExecutor.sol";
import "./mocks/MockSandboxExecutor.sol";
import "./mocks/MockReverter.sol";

contract AccountTest is Test {
    AccountV3Optimum implementation;
    ERC6551Registry public registry;

    MockERC721 public tokenCollection;
     
    function setUp() public {
        registry = new ERC6551Registry();

        implementation = new AccountV3Optimum(address(registry), address(1));

        tokenCollection = new MockERC721();

        // mint tokenId 1 during setup for accurate cold call gas measurement
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        tokenCollection.mint(user1, tokenId);
    }
   
}
