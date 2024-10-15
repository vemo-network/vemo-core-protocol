// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockReverter {
    error MockError();

    function fail() external pure returns (uint256) {
        revert MockError();
    }
}
