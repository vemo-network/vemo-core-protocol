// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC6551Executable {
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory);
}