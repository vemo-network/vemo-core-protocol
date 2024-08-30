// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutionTerm {
    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bool);

    function canExecute(address token, address to, uint256 value, bytes calldata data)
        external
        view
        returns (
            bool,
            uint8
        );
    
    function revokeTimeout() external returns(uint32);
}
