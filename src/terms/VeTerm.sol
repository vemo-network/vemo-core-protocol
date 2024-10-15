// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IExecutionTerm} from "../interfaces/IExecutionTerm.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAccountGuardian.sol";
import "@solidity-bytes-utils/BytesLib.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/LibExecutor.sol";
import "forge-std/console.sol";

/**
 * @title VeTerm
 * @notice major interface
 * 1. canExecute
 * 2. execute
 */
contract VeTerm is IExecutionTerm, UUPSUpgradeable, OwnableUpgradeable {
    address walletFactory;
    IAccountGuardian guardian;

    /** Term properties */
    address[] private _rewardAssets;
    uint16 public splitRatio; // for farmer - 1 bps = 0.01%, 100% = 10000 

    error NonWhitelistAction();

    enum ACTION_TYPE { EXECUTION, HARVESTING }
    mapping(bytes24 => bool) public allowedActions;
    mapping(bytes24 => bool) public harvestingActions;
    
    bool isLimitActionsMode;

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
        bytes24[] memory _actions,
        bytes24[] memory _harvestActions,
        address[] memory _rewardAssets_
    ) public onlyOwner {
        _rewardAssets = _rewardAssets_;

        for (uint i = 0; i < _actions.length; i++) {
            allowedActions[_actions[i]] = true;
        }

        for (uint i = 0; i < _harvestActions.length; i++) {
            harvestingActions[_harvestActions[i]] = true;
        }
        isLimitActionsMode = _actions.length > 0 ? true : false;
    }

    function disallowAction(ACTION_TYPE _type, bytes4 action) public onlyOwner {
        if (_type == ACTION_TYPE.EXECUTION) {
            allowedActions[action] = false;
        } else {
            harvestingActions[action] = false;
        }
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

        return harvestingActions[bytes24(abi.encodePacked(selector, bytes20(to)))];
    }

    function canExecute(address to, uint256 value, bytes calldata data)
        external
        view
    {   
        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }
        bytes24 actionKey = bytes24(abi.encodePacked(selector, bytes20(to)));

        if (isLimitActionsMode && !allowedActions[actionKey]) revert NonWhitelistAction();
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
        // no check for now
        return true;
    }
    
    function rewardAssets() external view returns(address[] memory) {
        return _rewardAssets;
    }

    receive() external payable {}

}
