// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "../interfaces/IAccountGuardian.sol";
import "../helpers/Errors.sol";

contract AccountProxy is Proxy {
    address immutable guardian;
    address immutable initialImplementation;

    constructor(address _guardian, address _initialImplementation) {
        if (_guardian == address(0) || _initialImplementation == address(0)) {
            revert InvalidImplementation();
        }
        guardian = _guardian;
        initialImplementation = _initialImplementation;
    }

    function initialize(address implementation) external {
        if (implementation != initialImplementation) {
            if (!IAccountGuardian(guardian).isTrustedImplementation(implementation)) {
                revert InvalidImplementation();
            }
        }
        if (ERC1967Utils.getImplementation() != address(0)) revert AlreadyInitialized();
        bytes memory _data;
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }

    function _implementation() internal view override returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /**
     * @notice Called whenever this account received Ether
     */
    receive() external payable {}
}