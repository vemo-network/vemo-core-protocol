// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "erc6551/interfaces/IERC6551Registry.sol";

import "./helpers/Errors.sol";
import "./interfaces/IWalletFactory.sol";
import "./interfaces/IDelegationCollection.sol";
import "./interfaces/darenft/ICollection.sol";
import "./interfaces/erc6551/IAccountProxy.sol";
import "./interfaces/ICollectionDeployer.sol";

contract WalletFactory is IERC721Receiver, IWalletFactory, UUPSUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /*
    * A factor to create token bound account
    * Vemo strictly follow ERC6551 standard, however to make the token bound address 
    * cross chains the salt is now fixed - as a prime in ECDSA space
    */
    uint256 private _TBA_SALT;

    // allow create new wallet collection role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice owner of the contract, could revoke or grantrole for others even himself
     */
    address private owner;

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
    mapping(address => mapping(uint256 => address)) private _tokenBoundAccounts;

    /**
     * @dev hashkey(name,symbol, dappURI) -> collection address
     */
    mapping (bytes32 hashkey => address collection) private _collectionRegistries;

    // dappURI for categorizing collections by project
    mapping (string uri => address[] collections) private dappURIs; // no longer use

    // delegate collection 
    address public collectionDeployer;

    address[] public delegations;

    function initialize(
        address _owner,
        address _accountRegistry,
        address _walletProxy,
        address _walletImpl
    ) public virtual initializer {
        if (_accountRegistry == address(0) ||
            _walletProxy == address(0) ||
            _walletImpl == address(0) ) revert InvalidERC6551Params();
        
        {
            __AccessControl_init_unchained();
            _grantRole(DEFAULT_ADMIN_ROLE, _owner);
            _grantRole(MINTER_ROLE, _owner);
        }

        {
            accountRegistry = _accountRegistry;
            walletProxy = _walletProxy;
            walletImpl = _walletImpl;
            owner = _owner;
        }
        
        {
            // a prime in ECDSA
            _TBA_SALT = 0x8cb91e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c;

            feeReceiver = _owner;
            depositFeeBps = 0;
            withdrawalFeeBps = 0;
        }
    }

    /**
     * Create wallet collection, for minter role only
     * @param collectionIndex salt for creating collection, use same salt return same address across chains
     * @param name collection name
     * @param symbol  collection symbol
     * @param descriptor token uri descriptor address
     */
    function createWalletCollection(
        uint160 collectionIndex,
        string calldata name,
        string calldata symbol,
        address descriptor
    ) public onlyRole(MINTER_ROLE) returns (address) {
        if (walletCollections[collectionIndex] != address(0)) return walletCollections[collectionIndex];

        address nftAddress = _deployNFTCollection(name, symbol, descriptor, collectionIndex);
        walletCollections[collectionIndex] = nftAddress;

        return nftAddress;
    }

    function _deployNFTCollection(
        string memory name,
        string memory symbol,
        address descriptor, 
        uint256 salt
    ) internal returns (address nftAddress) {
        bytes32 hashKey = keccak256(abi.encode(name, symbol, salt));
        if (_collectionRegistries[hashKey] != address(0)) revert DeployedCollection();

        nftAddress = ICollectionDeployer(collectionDeployer).createVemoCollection(
            name,
            symbol,
            salt,
            address(this),
            descriptor
        );

        _collectionRegistries[hashKey] = nftAddress;
        emit CollectionCreated(nftAddress, salt, name, symbol);
    }

    function createDelegateCollection(
        string memory _name,
        string memory _symbol,
        address _descriptor, 
        address _term,
        address _issuer
    ) public returns (address) {
        if (_descriptor == address(0)) revert InvalidDescriptor();
        address collection = ICollectionDeployer(collectionDeployer).createDelegateCollection(
            _name,
            _symbol,
            _descriptor, 
            _term,
            _issuer,
            address(this)
        );

        if (Ownable(collection).owner() != address(this)) revert IssuedByOtherFactory();

        delegations.push(collection);

        return collection;
    }

    /**
     * Create wallet of a specific collection with an URI for msg.sender
     * @param nftAddress collection managed by factory
     * @return tokenId 
     * @return tba - token bound account
     */
    function create(address nftAddress) public returns (uint256 tokenId, address tba){
        return createFor(nftAddress, msg.sender);
    }

    /**
     * Create wallet of a specific collection with an URI for a specific user
     * @param nftAddress collection managed by factory
     * @param receiver receiver
     * @return tokenId 
     * @return tba - token bound account 
     */
    function createFor(address nftAddress, address receiver) public override returns (uint256, address) {
        if (receiver == address(0)) revert InvalidInput();
        
        uint256 tokenId = ICollection(nftAddress).safeMint(receiver);
        address tba = _createAndInitializeTBA(nftAddress, tokenId, block.chainid);

        if (Ownable(tba).owner() != receiver) revert DeployedWallet();

        _tokenBoundAccounts[nftAddress][tokenId] = tba;

        emit WalletCreated(tba, nftAddress, tokenId, receiver, block.chainid);
        return (tokenId, tba);
    }

    /**
     * create TBA, in case user got token already, support crosschain
     * @param nftAddress collection managed by factory
     * @param tokenId tokenId
     * @param chainId chainid
     */
    function createTBA(address nftAddress, uint256 tokenId, uint256 chainId) public override  {
        address tba = _createAndInitializeTBA(nftAddress, tokenId, chainId);
        emit WalletCreated(tba, nftAddress, tokenId, address(0), chainId);
    }

    function _createAndInitializeTBA(address nftAddress, uint256 tokenId, uint256 chainId) internal returns (address) {
        address account = IERC6551Registry(accountRegistry).createAccount(
            walletProxy, bytes32(_TBA_SALT), chainId, nftAddress, tokenId
        );
        IAccountProxy(account).initialize(walletImpl);
        return account;
    }

    function setWalletCollection(uint160 collectionIndex, address _nft) public onlyRole(MINTER_ROLE) {
        if (walletCollections[collectionIndex] != address(0)) revert InvalidInput();

        walletCollections[collectionIndex] = _nft;
    }

    function setCollectionDeployer(address _deployer) public onlyRole(MINTER_ROLE) {
        collectionDeployer = _deployer;
    }

    function isOwner(address redeemer, uint256 tokenId, address nftAddress) internal view returns (bool) {
        if (IERC721(nftAddress).ownerOf(tokenId) != redeemer) return false;
        return true;
    }

    function getTokenBoundAccount(address nftAddress, uint256 tokenId) public view returns (address account) {
        return _tokenBoundAccounts[nftAddress][tokenId];
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        (newImplementation);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* utilities functions */
    function setAccountRegistry(address _accountRegistry) public onlyRole(DEFAULT_ADMIN_ROLE) {
        accountRegistry = _accountRegistry;
    }

    function setWalletImpl(address _walletImpl) public onlyRole(DEFAULT_ADMIN_ROLE) {
        walletImpl = _walletImpl;
    }

    function setWalletProxy(address _walletProxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        walletProxy = _walletProxy;
    }

    /**
     * Fee structures
     */
    address public feeReceiver;
    uint256 public depositFeeBps; // 1% in basis points
    uint256 public withdrawalFeeBps; // no fee

    function setFeeReceiver(address _receiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReceiver = _receiver;
    }

    function setFee(uint256 _depositFee, uint256 _withdrawalFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        depositFeeBps = _depositFee;
        withdrawalFeeBps = _withdrawalFee;
    }

    function depositTokens(address token, address walletAddress, uint256 amount) external {
        uint256 takenFee;
        if (depositFeeBps > 0) {
            takenFee = amount * depositFeeBps / 10000; // basis points formula
            {
                IERC20(token).safeTransferFrom(msg.sender, walletAddress, amount - takenFee);
                IERC20(token).safeTransferFrom(msg.sender, feeReceiver, takenFee);
            }
            return;
        }
        
        IERC20(token).safeTransferFrom(msg.sender, walletAddress, amount);
    }

    function depositETH(address walletAddress) payable external {
        if (msg.value == 0) revert InvalidDepositValue();

        uint256 takenFee;
        uint256 depositAmount = msg.value;
        if (depositFeeBps > 0) {
            takenFee = depositAmount * depositFeeBps / 10000; // basis points formula
            {
                _safeTransferETH(walletAddress, depositAmount - takenFee);
                _safeTransferETH(feeReceiver, takenFee);
            }
            return;
        }
        
        _safeTransferETH(walletAddress, depositAmount);
    }

    function _safeTransferETH(address receiver, uint256 amount) internal {
        (bool success, ) = receiver.call{value: amount}("");
        if (!success) revert InvalidDepositValue();
    }

    receive() external payable{}

    fallback() external payable {}

}
