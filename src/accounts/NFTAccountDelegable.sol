// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IDelegationCollection.sol";
import "../interfaces/IExecutionTerm.sol";
import "./AccountV3.sol";
import "../lib/LibExecutor.sol";
import "../lib/IterableMap.sol";
import "@solidity-bytes-utils/BytesLib.sol";

contract NFTAccountDelegable is AccountV3, UUPSUpgradeable {
    Store NFTRoles;
    using IterableMap for Store;

    error InvalidExecutor();

    event Delegate(
        address indexed delegateCollection,
        address receiver
    );

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

    modifier onlyValidExecutor() {
        _checkExecutorRole();
        _;
    }

    function _checkExecutorRole() internal view virtual {
        require(_isValidExecutor(_msgSender()));
    }

    function delegateExecute(address delegateCollection, address to, uint256 value, bytes calldata executeData, bytes calldata termData)
        external
        payable
        virtual
        returns (bytes memory)
    {
        if (!isDelegate(delegateCollection)) revert UnknownCollection();

        (, , uint256 tokenId) = ERC6551AccountLib.token();

        if (IERC721(delegateCollection).ownerOf(tokenId) != _msgSender()) revert InvalidImplementation();

        address term = IDelegationCollection(delegateCollection).term();
        
        IExecutionTerm(term).canExecute(to, value, executeData);

        if (IExecutionTerm(term).isHarvesting(to, value, executeData)) {
            return _harvestAndDistributeReward(term, delegateCollection, to, value, executeData);
        }

        return LibExecutor._execute(to, value, executeData, LibExecutor.OP_CALL);
    }

    function _harvestAndDistributeReward(address term, address delegationCollection, address to, uint256 value, bytes calldata executeData) internal returns (bytes memory) {
        address[] memory rewardTokens = IExecutionTerm(term).rewardAssets();
        uint16 splitRatio = IExecutionTerm(term).splitRatio();
        uint256[] memory rewards = new uint256[](rewardTokens.length);

        (,, uint256 tokenId) = ERC6551AccountLib.token();
        for (uint i = 0; i < rewardTokens.length; i++) {
            rewards[i] = _balanceOf(rewardTokens[i]);
        }

        LibExecutor._execute(to, value, executeData, LibExecutor.OP_CALL);

        address farmer = payable(
            IERC721(delegationCollection).ownerOf(tokenId)
        );

        for (uint i = 0; i < rewardTokens.length; i++) {
            rewards[i] = _balanceOf(rewardTokens[i]) - rewards[i];
            if (rewards[i] == 0) continue;

            if (rewardTokens[i] == address(0)) {
                farmer.call{value: rewards[i] * splitRatio / 10_000}("");
            } else {
                IERC20(rewardTokens[i]).transfer(farmer, rewards[i] * splitRatio / 10_000);
            }
        }

        IExecutionTerm(term).split(
            payable(owner()),
            payable(
                IERC721(delegationCollection).ownerOf(tokenId)
            ),
            rewards
        );

        return new bytes(4);
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
        override(AccountV3)
        returns (bool)
    {
        // non-delegate signature
        if (signature.length != 65+20+32+32) {
            return super._isValidSignature(hash, signature);
        }

        // extract delegation from signature
        address collection = BytesLib.toAddress(signature, 65);
        if (!isDelegate(collection)) revert UnknownCollection();

        address signer;
        ECDSA.RecoverError _error;
        (signer, _error,) = ECDSA.tryRecover(hash, BytesLib.slice(signature, 0, 65));

        if (_error != ECDSA.RecoverError.NoError) return false;

        (, address issuer, uint256 tokenId) = ERC6551AccountLib.token();

        require(IERC721(collection).ownerOf(tokenId) == signer, "!delegate");
        require(IDelegationCollection(collection).issuer() == issuer, "!issuer");

        address term = IDelegationCollection(collection).term();
        return IExecutionTerm(term).isValidSignature(hash, signature);
    }

    function _balanceOf(address _token) private view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        }
        
        return IERC20(_token).balanceOf(address(this));
    }

    /// role management
    function delegate(address delegation, address receiver) public onlyValidExecutor {
        (,,uint256 tokenId) = ERC6551AccountLib.token();

        IDelegationCollection(delegation).delegate(tokenId, receiver);
        NFTRoles.set(delegation, 1);

        emit Delegate(delegation, receiver);
    }

    function revoke(address delegation) public onlyValidExecutor {
        (,,uint256 tokenId) = ERC6551AccountLib.token();

        IDelegationCollection(delegation).revoke(tokenId);
    }

    function burn(address delegation) public {
        (,,uint256 tokenId) = ERC6551AccountLib.token();

        IDelegationCollection(delegation).burn(tokenId);
        NFTRoles.remove(delegation);
    }

    function isDelegate(address delegation) public view returns (bool) {
        return NFTRoles.get(delegation) > 0;
    }

    function delegates(address last, uint limit) public view returns(address[] memory _delegates) {
        (_delegates,) = NFTRoles.entries(last, limit);
    }

    // trustless: can be called by anyone
    function compactDelegates(address last, uint limit) external {
        NFTRoles.compact(last, limit);
    }
}