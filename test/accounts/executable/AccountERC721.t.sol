// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/proxy/Clones.sol";

// import "erc6551/ERC6551Registry.sol";
// import "erc6551/interfaces/IERC6551Account.sol";

// import "../../../src/accounts/AccountV3.sol";
// import "../../../src/AccountGuardian.sol";
// import "../../../src/accounts/AccountProxy.sol";

// import "./mocks/MockERC721.sol";
// import "./mocks/MockExecutor.sol";

// contract AccountERC721Test is Test {
//     MockERC721 public dummyERC721;

//     AccountV3 implementation;
//     ERC6551Registry public registry;

//     MockERC721 public tokenCollection;
     
//     function setUp() public {
//         dummyERC721 = new MockERC721();

//         implementation = new AccountV3(address(1), address(1), address(1));
//         registry = new ERC6551Registry();

//         tokenCollection = new MockERC721();
//     }

//     function testTransferERC721PreDeploy(uint256 tokenId) public {
//         address user1 = vm.addr(1);

//         address computedAccountInstance = registry.account(
//             address(implementation), 0, block.chainid, address(tokenCollection), tokenId
//         );

//         tokenCollection.mint(user1, tokenId);
//         assertEq(tokenCollection.ownerOf(tokenId), user1);

//         dummyERC721.mint(computedAccountInstance, 1);

//         assertEq(dummyERC721.balanceOf(computedAccountInstance), 1);
//         assertEq(dummyERC721.ownerOf(1), computedAccountInstance);

//         address accountAddress = registry.createAccount(
//             address(implementation), 0, block.chainid, address(tokenCollection), tokenId
//         );

//         AccountV3 account = AccountV3(payable(accountAddress));

//         bytes memory erc721TransferCall = abi.encodeWithSignature(
//             "safeTransferFrom(address,address,uint256)", accountAddress, user1, 1
//         );
//         vm.prank(user1);
//         account.execute(payable(address(dummyERC721)), 0, erc721TransferCall, 0);

//         assertEq(dummyERC721.balanceOf(address(account)), 0);
//         assertEq(dummyERC721.balanceOf(user1), 1);
//         assertEq(dummyERC721.ownerOf(1), user1);
//     }

//     function testTransferERC721PostDeploy(uint256 tokenId) public {
//         address user1 = vm.addr(1);

//         address accountAddress = registry.createAccount(
//             address(implementation), 0, block.chainid, address(tokenCollection), tokenId
//         );

//         tokenCollection.mint(user1, tokenId);
//         assertEq(tokenCollection.ownerOf(tokenId), user1);

//         dummyERC721.mint(accountAddress, 1);

//         assertEq(dummyERC721.balanceOf(accountAddress), 1);
//         assertEq(dummyERC721.ownerOf(1), accountAddress);

//         AccountV3 account = AccountV3(payable(accountAddress));

//         bytes memory erc721TransferCall =
//             abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", account, user1, 1);
//         vm.prank(user1);
//         account.execute(payable(address(dummyERC721)), 0, erc721TransferCall, 0);

//         assertEq(dummyERC721.balanceOf(accountAddress), 0);
//         assertEq(dummyERC721.balanceOf(user1), 1);
//         assertEq(dummyERC721.ownerOf(1), user1);
//     }

//     function testCannotOwnSelf() public {
//         address owner = vm.addr(1);
//         uint256 tokenId = 100;
//         bytes32 salt = bytes32(uint256(200));

//         tokenCollection.mint(owner, tokenId);

//         vm.prank(owner, owner);
//         address account = registry.createAccount(
//             address(implementation), salt, block.chainid, address(tokenCollection), tokenId
//         );

//         vm.prank(owner);
//         vm.expectRevert(OwnershipCycle.selector);
//         tokenCollection.safeTransferFrom(owner, account, tokenId);
//     }

//     function testOverrideERC721Receiver(uint256 tokenId) public {
//         address user1 = vm.addr(1);
//         address user2 = vm.addr(1);

//         tokenCollection.mint(user1, tokenId);
//         assertEq(tokenCollection.ownerOf(tokenId), user1);

//         address accountAddress = registry.account(
//             address(implementation), 0, block.chainid, address(tokenCollection), tokenId
//         );

//         vm.prank(user1);
//         dummyERC721.mint(accountAddress, 1);

//         assert(dummyERC721.balanceOf(accountAddress) == 1);
//         assert(dummyERC721.ownerOf(1) == accountAddress);

//         // transfer the 721 out
//         accountAddress = registry.createAccount(
//             address(implementation), 0, block.chainid, address(tokenCollection), tokenId
//         );
//         AccountV3 account = AccountV3(payable(accountAddress));

//         bytes memory erc721TransferCall =
//             abi.encodeWithSignature("transferFrom(address,address,uint256)", accountAddress, user2, 2);

//         vm.expectRevert(bytes4(keccak256(abi.encodePacked("NotAuthorized()"))));
//         account.execute(payable(address(dummyERC721)), 0, erc721TransferCall, 0);

//         vm.stopPrank();

//         erc721TransferCall =
//             abi.encodeWithSignature("transferFrom(address,address,uint256)", accountAddress, user2, 1);
//         vm.prank(user1);
//         account.execute(address(dummyERC721), 0, erc721TransferCall, 0);

//         assert(dummyERC721.balanceOf(user2) == 1);
//         assert(dummyERC721.ownerOf(1) == user2);
//     }
// }
