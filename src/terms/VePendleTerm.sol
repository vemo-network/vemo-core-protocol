// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExecutionTerm} from "../interfaces/IExecutionTerm.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAccountGuardian.sol";

/**
 * @title VePendleTerm
 * @notice Strategy to check if a call from delegate NFT of a TBA can be executed
 */
contract VePendleTerm is IExecutionTerm, UUPSUpgradeable, OwnableUpgradeable {
    address walletFactory;
    IAccountGuardian guardian;

    /** Term properties */
    address nftCollectionAddress;
    bytes4[] selectors;
    address[] implementations;

    function initialize(
        address _owner,
        address _walletFactory,
        address _guardian
    ) public virtual initializer {
         __Ownable_init(_owner);
        walletFactory = _walletFactory;
        guardian = IAccountGuardian(_guardian);
    }

    function setTermProperties(
        address _nftCollectionAddress,
        bytes4[] memory _selectors,
        address[] memory _implementations) public onlyOwner {
            nftCollectionAddress = _nftCollectionAddress;
            selectors = _selectors;
            _implementations = _implementations;
    }

    // TODO implement
    function canExecute(address token, address to, uint256 value, bytes calldata data)
        external
        override
        view
        returns (
            bool,
            uint8
        )
        {
            return (true, 0);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner virtual override {
        (newImplementation);
    }

    function revokeTimeout() public pure returns(uint32) {
        return 2592000; // 30 days
    }

    function _isValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        override(ERC4337Account, Signatory)
        returns (bool)
    {
        require(signature.length == 65+20+32+32, "invalid delegation signature length");

        // extract delegation signature
        bytes32 domain = BytesLib.toBytes32(signature, 65+20);
        bytes32 typeHash = BytesLib.toBytes32(signature, 65+65+20);

        // TODO: verify the domain and typeHash

        return true;
    }
}
