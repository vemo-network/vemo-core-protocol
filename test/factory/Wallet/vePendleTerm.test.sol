// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/terms/VePendleTerm.sol";

contract VePendleTermTest is Test {
    VePendleTerm vePendleTerm;
    address owner = address(0x123);
    address walletFactory = address(0x456);
    address guardian = address(0x789);
    
    address whitelistedAddress = address(0xabc);
    address nonWhitelistedAddress = address(0xdef);
    bytes4 validSelector = bytes4(keccak256("moveAssets(address,uint256)"));
    bytes4 invalidSelector = bytes4(keccak256("nonExistentFunction()"));
    
    function setUp() public {
        vePendleTerm = new VePendleTerm();
        vePendleTerm.initialize(owner, walletFactory, guardian);
    }

    function testCanExecute_ValidWhitelistedAddressAndSelector() public {
        bytes memory data = abi.encodeWithSelector(validSelector, whitelistedAddress, 100);
        (bool success, uint8 errorCode) = vePendleTerm.canExecute(whitelistedAddress, 0, data);
        
        assertTrue(success);
        assertEq(errorCode, 0);

        setTermProperties();

        (success, errorCode) = vePendleTerm.canExecute(whitelistedAddress, 0, data);
        assertTrue(success);
        assertEq(errorCode, 0);
    }

    function setTermProperties() internal {
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistedAddress;
        
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = validSelector;
        bytes4[] memory _harvestSelectors;
        address[] memory _whitelist;
        address[] memory _rewardAssets_ = new address[](1);
        _rewardAssets_[0] = address(0);
        
        vm.startPrank(owner);
        vePendleTerm.setTermProperties(address(0), selectors, _harvestSelectors, whitelist, _whitelist );
    }

    function testCanExecute_NonWhitelistedAddress() public {
        bytes memory data = abi.encodeWithSelector(validSelector, nonWhitelistedAddress, 100);
        (bool success, uint8 errorCode) = vePendleTerm.canExecute(address(0), 0, data);
        
        assertTrue(success);
        assertEq(errorCode, 0);

        setTermProperties();

        (success, errorCode) = vePendleTerm.canExecute(address(0), 0, data);
        
        assertFalse(success);
        assertEq(errorCode, 1);
    }

    function testCanExecute_InvalidSelector() public {
        bytes memory data = abi.encodeWithSelector(invalidSelector, whitelistedAddress, 100);
        
        (bool success, uint8 errorCode) = vePendleTerm.canExecute(whitelistedAddress, 0, data);
        
        assertTrue(success);
        assertEq(errorCode, 0);

        setTermProperties();

        (success, errorCode) = vePendleTerm.canExecute(whitelistedAddress, 0, data);

        assertFalse(success);
        assertEq(errorCode, 2);
    }

    function testCanExecute_NonWhitelistedAddressAndInvalidSelector() public {
        bytes memory data = abi.encodeWithSelector(invalidSelector, nonWhitelistedAddress, 100);
        (bool success, uint8 errorCode) = vePendleTerm.canExecute(nonWhitelistedAddress, 0, data);
        
        assertTrue(success);
        assertEq(errorCode, 0);

        setTermProperties();

        (success, errorCode) = vePendleTerm.canExecute(nonWhitelistedAddress, 0, data);
        assertFalse(success);
        assertEq(errorCode, 1);
    }
}
