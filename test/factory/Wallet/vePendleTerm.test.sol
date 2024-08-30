// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../../../src/terms/VePendleTerm.sol";

// contract VePendleTermTest is Test {
//     VePendleTerm vePendleTerm;
//     address owner = address(0x123);
//     address walletFactory = address(0x456);
//     address guardian = address(0x789);
    
//     address whitelistedAddress = address(0xabc);
//     address nonWhitelistedAddress = address(0xdef);
//     bytes4 validSelector = bytes4(keccak256("moveAssets(address,uint256)"));
//     bytes4 invalidSelector = bytes4(keccak256("nonExistentFunction()"));
    
//     function setUp() public {
//         vePendleTerm = new VePendleTerm();
//         vePendleTerm.initialize(owner, walletFactory, guardian);
        
//         address[] memory whitelist;
//         whitelist.push(whitelistedAddress);
        
//         bytes4[] memory selectors;
//         selectors.push(validSelector);
        
//         address;
        
//         vePendleTerm.setTermProperties(address(0), selectors, whitelist, whitelistedAddress);
//     }

//     function testCanExecute_ValidWhitelistedAddressAndSelector() public {
//         // Prepare calldata with a valid selector
//         bytes memory data = abi.encodeWithSelector(validSelector, whitelistedAddress, 100);
        
//         // Call canExecute with whitelisted address and valid selector
//         (bool success, uint8 errorCode) = vePendleTerm.canExecute(address(0), whitelistedAddress, 0, data);
        
//         // Assert that the execution is successful
//         assertTrue(success);
//         assertEq(errorCode, 0);
//     }

//     function testCanExecute_NonWhitelistedAddress() public {
//         // Prepare calldata with a valid selector
//         bytes memory data = abi.encodeWithSelector(validSelector, nonWhitelistedAddress, 100);
        
//         // Call canExecute with non-whitelisted address
//         (bool success, uint8 errorCode) = vePendleTerm.canExecute(address(0), nonWhitelistedAddress, 0, data);
        
//         // Assert that the execution fails due to non-whitelisted address
//         assertFalse(success);
//         assertEq(errorCode, 1);
//     }

//     function testCanExecute_InvalidSelector() public {
//         // Prepare calldata with an invalid selector
//         bytes memory data = abi.encodeWithSelector(invalidSelector, whitelistedAddress, 100);
        
//         // Call canExecute with whitelisted address but invalid selector
//         (bool success, uint8 errorCode) = vePendleTerm.canExecute(address(0), whitelistedAddress, 0, data);
        
//         // Assert that the execution fails due to invalid selector
//         assertFalse(success);
//         assertEq(errorCode, 2);
//     }

//     function testCanExecute_NonWhitelistedAddressAndInvalidSelector() public {
//         // Prepare calldata with an invalid selector
//         bytes memory data = abi.encodeWithSelector(invalidSelector, nonWhitelistedAddress, 100);
        
//         // Call canExecute with non-whitelisted address and invalid selector
//         (bool success, uint8 errorCode) = vePendleTerm.canExecute(address(0), nonWhitelistedAddress, 0, data);
        
//         // Assert that the execution fails due to non-whitelisted address (errorCode 1 is prioritized)
//         assertFalse(success);
//         assertEq(errorCode, 1);
//     }
// }
