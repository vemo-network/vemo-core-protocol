// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {BaseAccount as BaseERC4337Account} from
    "@account-abstraction/contracts/core/BaseAccount.sol";

import "../helpers/Errors.sol";

/**
 * @title ERC-4337 Support
 * @dev Implements ERC-4337 account support
 */
abstract contract ERC4337Account is BaseERC4337Account {
    using MessageHashUtils for bytes32;

    IEntryPoint immutable _entryPoint;

    constructor(address entryPoint_) {
        if (entryPoint_ == address(0)) revert InvalidEntryPoint();
        _entryPoint = IEntryPoint(entryPoint_);
    }

    /**
     * @dev See {BaseERC4337Account-entryPoint}
     */
    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev See {BaseERC4337Account-_validateSignature}
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (_isValidSignature(_getUserOpSignatureHash(userOp, userOpHash), userOp.signature)) {
            return 0;
        }

        return 1;
    }

    /**
     * @dev Returns the user operation hash that should be signed by the account owner
     */
    function _getUserOpSignatureHash(PackedUserOperation calldata, bytes32 userOpHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return userOpHash.toEthSignedMessageHash();
    }

    function _isValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        returns (bool);
}