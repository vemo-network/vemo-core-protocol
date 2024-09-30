// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./AccountV3Optimum.sol";

contract AccountV3Upgradable is AccountV3Optimum, UUPSUpgradeable {
    constructor(
        address erc6551Registry,
        address guardian
    ) AccountV3Optimum(erc6551Registry, guardian) {}

    function _authorizeUpgrade(address implementation) internal virtual override {
        if (!guardian.isTrustedImplementation(implementation)) revert InvalidImplementation();
        if (!_isValidExecutor(_msgSender())) revert NotAuthorized();
    }
}