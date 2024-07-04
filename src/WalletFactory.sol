// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "erc6551/interfaces/IERC6551Registry.sol";

import "./helpers/Errors.sol";
import "./interfaces/IWalletFactory.sol";
import "./interfaces/darenft/ICollection.sol";
import "./interfaces/erc6551/IAccountProxy.sol";
import "./helpers/VemoWalletCollection.sol";

contract WalletFactory is IERC721Receiver, IWalletFactory, UUPSUpgradeable, AccessControlUpgradeable {
    /*
    * tokenIdWalletg to create token boud account
    * vemo strictly follow ERC6551 standard, however to make the tokenIdWallett 
    * between chains the salt is now fixed - as a prime in ECDSA space
    */
    uint256 private _TBA_SALT;

    // allow create new wallet collection role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice owner of the contract, could revoke or grantrole for others even himself
     */
    address public owner;

    /**
     * @notice configurations to generate determistic wallet address
     */

    // @notice a decenterlized hub to create wallet
    address public accountRegistry;

    // @notice wallet implementation - business logic layer
    address public walletImpl;

    address public walletProxy;
    /**** -------------------------  */

    /**
     * @notice a mapping, stores the wallet collection by index
     * this helps vemo easily issue same collection address if needed cross chains
     */
    mapping(uint160 => address) public walletCollections;

    /**
     * @dev store the wallet address with NFT - tokenID
     */
    mapping(address => mapping(uint256 => address)) private _tokenIdWallet;

    /**
     * @dev hashkey(name,symbol, dappURI) -> collection address
     */
    mapping (bytes32 hashkey => address collection) private _collectionRegistries;

    // dappURI for categorizing collections by project
    mapping (string uri => address[] collections) private dappURIs;

    function initialize(
        address _owner,
        address _accountRegistry,
        address _walletProxy,
        address _walletImpl
    ) public virtual initializer {
        if (_accountRegistry == address(0) ||
            _walletProxy == address(0) ||
            _walletImpl == address(0) ) revert InvalidERC6551Params();

        __AccessControl_init_unchained();
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);

        accountRegistry = _accountRegistry;
        walletProxy = _walletProxy;
        walletImpl = _walletImpl;
        owner = _owner;

        // a prime in ECDSA
        _TBA_SALT = 0x8CB91E82A3386D28036D6F63D1E6EFD90031D3E8A56E75DA9F0B021F40B0BC4C;
    }

    /**
     * Create wallet collection, for minter role only
     * @param collectionIndex salt for creating collection, use same salt return same address across chains
     * @param name collection name
     * @param symbol  collection symbol
     * @param dappURI  for categorizing collection ie
     */
    function createWalletCollection(
        uint160 collectionIndex,
        string calldata name,
        string calldata symbol,
        string calldata dappURI 
    ) public onlyRole(MINTER_ROLE) returns (address) {
        if (walletCollections[collectionIndex] != address(0)) return walletCollections[collectionIndex];

        address nftAddress = _deployNFTCollection(name, symbol, dappURI, collectionIndex);
        walletCollections[collectionIndex] = nftAddress;
        dappURIs[dappURI].push(nftAddress);

        return nftAddress;
    }

    function _deployNFTCollection(
        string memory name,
        string memory symbol,
        string memory dappURI,
        uint256 salt
    ) internal returns (address nftAddress) {
        bytes32 hashKey = keccak256(abi.encode(name, symbol, dappURI));
        if (_collectionRegistries[hashKey] != address(0)) revert DeployedCollection();

        bytes memory bytecode = abi.encodePacked(
            type(VemoWalletCollection).creationCode,
            abi.encode(
                name,
                symbol,
                address(this)
            )
        );
        bytes32 saltHash = keccak256(abi.encodePacked(salt));

        assembly {
            nftAddress := create2(0, add(bytecode, 0x20), mload(bytecode), saltHash)
            if iszero(extcodesize(nftAddress)) {
                revert(0, 0)
            }
        }

        if (VemoWalletCollection(nftAddress).owner() != address(this)) revert IssuedByOtherFactory();

        _collectionRegistries[hashKey] = nftAddress;
        emit CollectionCreated(nftAddress, salt, name, symbol, dappURI);
    }

    /**
     * Create wallet of a specific collection with an URI for msg.sender
     * @param nftAddress collection managed by factory
     * @param tokenUri tokenURI
     * @return tokenId 
     * @return tokenIdWallet 
     */
    function create(address nftAddress, string memory tokenUri) public returns (uint256 tokenId, address tokenIdWallet){
        return createFor(nftAddress, tokenUri, msg.sender);
    }

    /**
     * Create wallet of a specific collection with an URI for a specific user
     * @param nftAddress collection managed by factory
     * @param tokenUri tokenURI
     * @param receiver receiver
     * @return tokenId 
     * @return tokenIdWallet 
     */
    function createFor(address nftAddress, string memory tokenUri, address receiver) public override returns (uint256, address) {
        if (receiver == address(0)) revert InvalidInput();
        
        uint256 tokenId = ICollection(nftAddress).safeMint(receiver, tokenUri);
        address tba = _createAndInitializeTBA(nftAddress, tokenId, block.chainid);

        if (Ownable(tba).owner() != receiver) revert DeployedWallet();

        _tokenIdWallet[nftAddress][tokenId] = tba;

        emit WalletCreated(tba, nftAddress, tokenId, receiver);
        return (tokenId, tba);
    }

    /**
     * create TBA, in case user got token already, support crosschain
     * @param nftAddress collection managed by factory
     * @param tokenId tokenId
     * @param chainId chainid
     */
    function createTBA(address nftAddress, uint256 tokenId, uint256 chainId) public override  {
        address account = _createAndInitializeTBA(nftAddress, tokenId, chainId);
        emit TBACreated(nftAddress, tokenId, account, chainId);
    }

    function _createAndInitializeTBA(address nftAddress, uint256 tokenId, uint256 chainId) private returns (address) {
        address account = IERC6551Registry(accountRegistry).createAccount(
            walletProxy, bytes32(_TBA_SALT), chainId, nftAddress, tokenId
        );
        IAccountProxy(account).initialize(walletImpl);
        return account;
    }

    function setWalletCollection(uint160 collectionIndex, address _nft, string calldata dappURI) public onlyRole(MINTER_ROLE) {
        if (walletCollections[collectionIndex] != address(0)) revert InvalidInput();

        walletCollections[collectionIndex] = _nft;
        dappURIs[dappURI].push(_nft);
    }

    function getAllTokensNftsByDappURI(string calldata dappURI) public view returns (address[] memory nfts) {
        return dappURIs[dappURI];
    }

    function isOwner(address redeemer, uint256 tokenId, address nftAddress) internal view returns (bool) {
        if (IERC721(nftAddress).ownerOf(tokenId) != redeemer) return false;
        return true;
    }

    function getTokenBoundAccount(address nftAddress, uint256 tokenId) public view returns (address account) {
        return _tokenIdWallet[nftAddress][tokenId];
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        (newImplementation);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setAccountRegistry(address _accountRegistry) public onlyRole(DEFAULT_ADMIN_ROLE) {
        accountRegistry = _accountRegistry;
    }

    function setWalletImpl(address _walletImpl) public onlyRole(DEFAULT_ADMIN_ROLE) {
        walletImpl = _walletImpl;
    }

    function setWalletProxy(address _walletProxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        walletProxy = _walletProxy;
    }

}
