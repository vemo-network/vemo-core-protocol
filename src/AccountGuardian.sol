// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
contract AccountGuardian is Ownable {
    /**
     * @dev mapping from implementation => is trusted
     */
    mapping(address => bool) public isTrustedImplementation;

    /**
     * @dev mapping from cross-chain executor => is trusted
     */
    mapping(address => bool) public isTrustedExecutor;

    event TrustedImplementationUpdated(address implementation, bool trusted);
    event TrustedExecutorUpdated(address executor, bool trusted);

    constructor(address owner) Ownable(owner) {
    }

    /**
     * @dev Sets a given implementation address as trusted, allowing accounts to upgrade to this
     * implementation
     */
    function setTrustedImplementation(address implementation, bool trusted) external onlyOwner {
        isTrustedImplementation[implementation] = trusted;
        emit TrustedImplementationUpdated(implementation, trusted);
    }

    /**
     * @dev Sets a given cross-chain executor address as trusted, allowing it to relay operations to
     * accounts on non-native chains
     */
    function setTrustedExecutor(address executor, bool trusted) external onlyOwner {
        isTrustedExecutor[executor] = trusted;
        emit TrustedExecutorUpdated(executor, trusted);
    }

}
