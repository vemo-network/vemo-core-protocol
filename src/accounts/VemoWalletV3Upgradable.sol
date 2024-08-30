// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/IDelegationCollection.sol";
import "../interfaces/IExecutionTerm.sol";
import "./AccountV3.sol";
import "../lib/LibExecutor.sol";
import "@solidity-bytes-utils/BytesLib.sol";

contract VemoWalletV3Upgradable is AccountV3, UUPSUpgradeable {
    address delegationCollection;

    constructor(
        address entryPoint_,
        address multicallForwarder,
        address erc6551Registry,
        address guardian
    ) AccountV3(entryPoint_, multicallForwarder, erc6551Registry, guardian) {}

    function _authorizeUpgrade(address implementation) internal virtual override {
        if (!guardian.isTrustedImplementation(implementation)) revert InvalidImplementation();
        if (!_isValidExecutor(_msgSender())) revert NotAuthorized();
    }

    modifier onlyOwner() {
        _checkRole();
        _;
    }

    function _checkRole() internal view virtual {
        require(msg.sender == owner());
    }

    function delegateExecute(address collection, address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        virtual
        returns (bytes memory)
    {
        address term = IDelegationCollection(collection).term();
        (uint256 chainId, address tokenContract, uint256 tokenId) = ERC6551AccountLib.token();

        // TODO: verify the collection is CREATE2-ed from tokenContract and term

        if (!guardian.isTrustedImplementation(term)) revert InvalidImplementation();

        (bool canExecute, uint8 errorCode) =  IExecutionTerm(term).canExecute(tokenContract, to, value, data);

        if (!canExecute) revert InvalidImplementation();
        
        return LibExecutor._execute(to, value, data, operation);
    }

    function setDelegate(address _delegationCollection) external onlyOwner {
        delegationCollection = _delegationCollection;
    }

    function getDelegate() external view returns(address) {
        return delegationCollection;
    }

    /**
     * Determines if a given hash and signature are valid for this account
     * @param hash Hash of signed data
     * @param signature ECDSA signature or encoded contract signature (v=0)
     */
    function _isValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        virtual
        override(ERC4337Account, Signatory)
        returns (bool)
    {
        // smart contract signature
        if (uint8(signature[64]) == 0) {
            return super._isValidSignature(hash, signature);
        }

        // non-delegate signature
        if (signature.length == 65) {
            return super._isValidSignature(hash, signature);
        }

        require(signature.length == 65+20+32+32, "invalid delegation signature length");

        // extract delegation signature
        address delegationCollection = BytesLib.toAddress(signature, 20);
        signature = BytesLib.slice(signature, 0, 65);

        address signer;
        ECDSA.RecoverError _error;
        (signer, _error,) = ECDSA.tryRecover(hash, signature);

        if (_error != ECDSA.RecoverError.NoError) return false;

        (address issuer,, uint256 tokenId) = ERC6551AccountLib.token();
        require(IERC721(delegationCollection).ownerOf(tokenId) == signer, "!delegate");

        address term = delegationCollection.term();
        // TODO: verify delegationCollection = CREATE2(issuer, term);
        return term.isValidSignature(hash, signature);
    }
}