// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/IDelegationCollection.sol";
import "../interfaces/IExecutionTerm.sol";
import "./AccountV3.sol";
import "../lib/LibExecutor.sol";

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

        if (!guardian.isTrustedImplementation(term)) revert InvalidImplementation();

        (bool canExecute, uint8 errorCode) =  IExecutionTerm(term).canExecute(tokenContract, to, value, data);

        if (!canExecute) revert InvalidImplementation();
        
        return LibExecutor._execute(to, value, data, operation);
    }

    function setDelegate(address _delegationCollection) external onlyOwner {
        delegationCollection = _delegationCollection;
    }

    function isValidSigner(address signer, bytes calldata data)
        external
        view override
        returns (bytes4 magicValue)
    {
        if (_isValidSigner(signer, data)) {
            return IERC6551Account.isValidSigner.selector;
        }

        (,, uint256 tokenId) = ERC6551AccountLib.token();
        if (IERC721(delegationCollection).ownerOf(tokenId) == signer) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }
}