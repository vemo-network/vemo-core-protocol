// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutionTerm {
    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool);
    
    function canExecute(address to, uint256 value, bytes calldata data)
        external
        view;
        // returns (
        //     bool,
        //     uint8
        // );
    
    function isHarvesting(address to, uint256 value, bytes calldata data)
        external
        view
        returns (
            bool
        );
    
    function split(
        address payable _owner,
        address payable _farmer,
        uint256[] memory rewards
    ) external;

    function revokeTimeout() external returns(uint32);

    function rewardAssets() external returns(address[] memory);

    function setSplitRatio(uint16 _splitRatio) external;
    function splitRatio() external returns(uint16 _splitRatio);

    function setTermProperties(
        address _nftCollectionAddress,
        bytes4[] memory _selectors,
        bytes4[] memory _harvestSelectors,
        address[] memory _whitelist,
        address[] memory _rewardAssets_
    ) external;
    
}
