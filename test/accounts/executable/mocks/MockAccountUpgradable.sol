// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../../../../src/accounts/AccountV3Optimum.sol";
import "../../../../src/accounts/AccountV3Upgradable.sol";

contract MockAccountUpgradable is AccountV3Upgradable {
    constructor(
        address multicallForwarder,
        address erc6551Registry,
        address guardian
    ) AccountV3Upgradable(multicallForwarder, erc6551Registry, guardian) {}

    function customFunction() external pure returns (uint256) {
        return 12345;
    }
}