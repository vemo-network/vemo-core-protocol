// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/terms/VeTerm.sol";
import "../../../src/terms/VeTerm.sol";

contract VeTermTest is Test {
    VeTerm vePendleTerm;
    address owner = address(0x123);
    address walletFactory = address(0x456);
    address guardian = address(0x789);
    
    address whitelistedAddress = address(0xabc);
    address nonWhitelistedAddress = address(0xdef);
    bytes4 validSelector = bytes4(keccak256("moveAssets(address,uint256)"));
    bytes4 invalidSelector = bytes4(keccak256("nonExistentFunction()"));
    
    function setUp() public {
        vePendleTerm = new VeTerm();
        vePendleTerm.initialize(owner, walletFactory, guardian);
    }

    function testCanExecute_ValidWhitelistedAddressAndSelector() public {
        bytes memory data = abi.encodeWithSelector(validSelector, whitelistedAddress, 100);
        vePendleTerm.canExecute(whitelistedAddress, 0, data);
        
        setTermProperties();

        vePendleTerm.canExecute(whitelistedAddress, 0, data);
    }

    function setTermProperties() internal {
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistedAddress;
        
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = validSelector;
        address[] memory _rewardAssets_ = new address[](1);
        _rewardAssets_[0] = address(0);
        
        bytes24[] memory actions = new bytes24[](1);
        actions[0] = bytes24(abi.encodePacked(selectors[0], whitelist[0]));

        bytes24[] memory _harvestActions ;
        
        vm.startPrank(owner);
        vePendleTerm.setTermProperties(address(0), actions, _harvestActions, _rewardAssets_ );
    }

    function testCanExecute_NonWhitelistedAddress() public {
        bytes memory data = abi.encodeWithSelector(validSelector, nonWhitelistedAddress, 100);
        vePendleTerm.canExecute(address(0), 0, data);

        setTermProperties();

        vm.expectRevert(bytes4(keccak256(abi.encodePacked("NonWhitelistAction()"))));
        vePendleTerm.canExecute(address(0), 0, data);

    }

    function testCanExecute_InvalidSelector() public {
        bytes memory data = abi.encodeWithSelector(invalidSelector, whitelistedAddress, 100);
        vePendleTerm.canExecute(whitelistedAddress, 0, data);

        setTermProperties();

        vm.expectRevert(bytes4(keccak256(abi.encodePacked("NonWhitelistAction()"))));
        vePendleTerm.canExecute(whitelistedAddress, 0, data);
    }

    function testCanExecute_NonWhitelistedAddressAndInvalidSelector() public {
        bytes memory data = abi.encodeWithSelector(invalidSelector, nonWhitelistedAddress, 100);
        vePendleTerm.canExecute(nonWhitelistedAddress, 0, data);
        setTermProperties();

        vm.expectRevert(bytes4(keccak256(abi.encodePacked("NonWhitelistAction()"))));
        vePendleTerm.canExecute(nonWhitelistedAddress, 0, data);
    }
}

// contract GasComparisonTest is Test {
//     address owner = address(0x123);
//     address walletFactory = address(0x456);
//     address guardian = address(0x789);
    
//     VeTerm original;
//     VeTermOptimum optimized;

//     function setUp() public {
//         original = new VeTerm();
//         original.initialize(owner, walletFactory, guardian);
//         optimized = new VeTermOptimum();
//         optimized.initialize(owner, walletFactory, guardian);

//         address[] memory whitelist = new address[](2);
//         whitelist[0] = address(1);
//         whitelist[1] = address(2);
        
//         bytes4[] memory selectors = new bytes4[](2);
//         selectors[0] = bytes4(keccak256("transfer(address,uint256)"));
//         selectors[1] = bytes4(keccak256("approve(address,uint256)"));

//         bytes4[] memory _harvestSelectors;
//         address[] memory _rewardAssets_ = new address[](1);
//         _rewardAssets_[0] = address(0);

//         bytes24[] memory actions = new bytes24[](10);
//         actions[0] = bytes24(abi.encodePacked(selectors[0], address(1)));
//         actions[1] = bytes24(abi.encodePacked(selectors[1], address(2)));
//         actions[7] = bytes24(abi.encodePacked(selectors[1], address(2)));

//         vm.startPrank(owner);
//         original.setTermProperties(address(0), selectors, _harvestSelectors, whitelist, _rewardAssets_ );

//         bytes24[] memory _harvestActions =  new bytes24[](10);
//         actions[0] = bytes24(abi.encodePacked(selectors[0], address(1)));
//         actions[1] = bytes24(abi.encodePacked(selectors[0], address(1)));
//         actions[3] = bytes24(abi.encodePacked(selectors[0], address(1)));

//         optimized.setTermProperties(address(0), actions, _harvestActions, _rewardAssets_ );

//     }

//     function testGasOriginal() public view {
//         original.canExecute(address(1), 100, abi.encodeWithSignature("approve(address,uint256)", address(2), 50));
//     }

//     function testGasOriginalMixed() public {
//         original.canExecute(address(1), 100, abi.encodeWithSignature("approve(address,uint256)", address(2), 50));
//     }

//     function testCompareGasExecute() public {
//         uint256 gasStartOriginal = gasleft();
//         original.canExecute(address(1), 100, abi.encodeWithSignature("approve(address,uint256)", address(2), 50));
//         uint256 gasUsedOriginal = gasStartOriginal - gasleft();

//         gasStartOriginal = gasleft();
//         optimized.canExecute(address(1), 100, abi.encodeWithSignature("transfer(address,uint256)", address(2), 50));
//         uint256 gasUsedOptimized = gasStartOriginal - gasleft();

//         assertGt(gasUsedOriginal, gasUsedOptimized + gasUsedOptimized/2); 
//     }

//     function testGasOptimized() public view {
//         optimized.canExecute(address(1), 100, abi.encodeWithSignature("transfer(address,uint256)", address(2), 50));
//     }

//     function testGasOriginalNonWhitelisted() public {
//         vm.expectRevert();
//         original.canExecute(address(3), 100, abi.encodeWithSignature("transfer(address,uint256)", address(2), 50));
//     }

//     function testGasOptimizedNonWhitelisted() public {
//         vm.expectRevert();
//         optimized.canExecute(address(3), 100, abi.encodeWithSignature("transfer(address,uint256)", address(2), 50));
//     }

//     function testGasOriginalInvalidSelector() public {
//         vm.expectRevert();
//         original.canExecute(address(1), 100, abi.encodeWithSignature("invalidFunction()", address(2), 50));
//     }

//     function testGasOptimizedInvalidSelector() public {
//         vm.expectRevert();
//         optimized.canExecute(address(1), 100, abi.encodeWithSignature("invalidFunction()", address(2), 50));
//     }
// }
