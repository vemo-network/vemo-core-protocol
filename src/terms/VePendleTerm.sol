// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExecutionTerm} from "../interfaces/IExecutionTerm.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAccountGuardian.sol";
import "@solidity-bytes-utils/BytesLib.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @title VePendleTerm
 * @notice Strategy to check if a call from delegate NFT of a TBA can be executed
 */
contract VePendleTerm is IExecutionTerm, UUPSUpgradeable, OwnableUpgradeable {
    address walletFactory;
    IAccountGuardian guardian;

    /** Term properties */
    address nftCollectionAddress;
    bytes4[] public selectors;
    address[] public whitelist;
    address[] private _rewardAssets;
    bytes4[] public harvestSelectors;
    uint16 public splitRatio; // for farmer - 1 bps = 0.01%, 100% = 10000 

    function initialize(
        address _owner,
        address _walletFactory,
        address _guardian
    ) public virtual initializer {
         __Ownable_init(_owner);
        walletFactory = _walletFactory;
        guardian = IAccountGuardian(_guardian);
        splitRatio = 1; // 1 bps -  mean 0.01%, 100% = 10000 
    }

    function setTermProperties(
        address _nftCollectionAddress,
        bytes4[] memory _selectors,
        bytes4[] memory _harvestSelectors,
        address[] memory _whitelist,
        address[] memory _rewardAssets_
    ) public onlyOwner {
        nftCollectionAddress = _nftCollectionAddress;
        selectors = _selectors;
        harvestSelectors = _harvestSelectors;
        whitelist = _whitelist;
        _rewardAssets = _rewardAssets_;
    }

    function setSplitRatio(
        uint16 _splitRatio
    ) public onlyOwner {
        splitRatio = _splitRatio;
    }

    function isHarvesting(address to, uint256 value, bytes calldata data) external view returns (bool) {
        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }
        for (uint256 i = 0; i < harvestSelectors.length; i++) {
            if (harvestSelectors[i] == selector) {
                return true;
            }
        }

        return false;
    }

    function split(
        address payable _owner,
        address payable _farmer,
        uint256[] memory rewards
    ) public {
        for (uint i = 0; i < _rewardAssets.length; i++) {
            uint256 amountFarmer = (rewards[i] * splitRatio) / 10000;
            uint256 amountOwner = rewards[i] - amountFarmer;
            
            // avoid reentrancy
            rewards[i] = 0;

            if (_rewardAssets[i] != address(0)) {
                IERC20(_rewardAssets[i]).transferFrom(address(this), _owner, amountOwner);
                IERC20(_rewardAssets[i]).transferFrom(address(this), _farmer, amountFarmer);
            } else {
                _owner.call{value: amountOwner}("");
                _farmer.call{value: amountFarmer}("");
            }
        }
    }

    function canExecute(address to, uint256 value, bytes calldata data)
        external
        override
        view
        returns (bool,uint8)
    {
        bool isWhitelisted = whitelist.length > 0 ? false : true;

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == to) {
                isWhitelisted = true;
                break;
            }
        }
        if (!isWhitelisted) {
            return (false, 1); // "to address not whitelisted"
        }

        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }
        
        bool isValidSelector = selectors.length > 0 ? false : true;
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectors[i] == selector) {
                isValidSelector = true;
                break;
            }
        }

        if (!isValidSelector) {
            return (false, 2); // "invalid function selector"
        }

        return (true, 0); //success
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner virtual override {
        (newImplementation);
    }

    function revokeTimeout() public pure returns(uint32) {
        return 2592000; // 30 days
    }

    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool)
    {
        // require(signature.length == 65+20+32+32, "invalid delegation signature length");

        // extract delegation signature
        // bytes32 domain = BytesLib.toBytes32(signature, 65+20);
        // bytes32 typeHash = BytesLib.toBytes32(signature, 65+65+20);

        // TODO: verify the domain and typeHash

        return true;
    }
    
    function rewardAssets() external view returns(address[] memory) {
        return _rewardAssets;
    }

    receive() external payable {}

}
