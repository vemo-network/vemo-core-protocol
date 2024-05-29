// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IDynamic.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IVoucherFactory.sol";
import "./interfaces/IVoucherAccount.sol";
import "./interfaces/IAccountRegistry.sol";

import "./Common.sol";

contract VoucherFactory is IERC721Receiver, IVoucherFactory, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // Contract deployer address
    address public _owner;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == _owner || msg.sender == address(this), "only owner");
    }

    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    bytes private constant BALANCE_KEY = "BALANCE";
    uint8 private constant FEE_STATUS = 1;

    bytes32 private constant WRITER_ROLE = keccak256("WRITER_ROLE");

    uint256 private _salt; // used for create erc6551 account

    uint256 public constant MAX_INT = type(uint256).max;

    mapping(address => address) private tokenNftMap;
    address[] private _tokens;
    address[] private _nfts;
    mapping(address => mapping(uint256 => address)) private _tbaNftMap;

    address public protocolFactoryAddress;
    address public dataRegistry;
    address public accountRegistry;
    address public voucherAccountImpl;

    // data schemas
    event VoucherCreated(
        address indexed account,
        address indexed currency,
        uint256 amount,
        address indexed nftCollection,
        uint256 tokenId
    );

    function initialize(
        address owner,
        address _factoryAddress,
        address _dataRegistry,
        address _accountRegistry,
        address _voucherAccountImpl
    ) public virtual initializer {
        require(_factoryAddress != address(0), "Invalid ERC20 token address");
        require(_dataRegistry != address(0), "Invalid Data registry address");
        require(_accountRegistry != address(0), "Invalid ERC6551 registry address");
        require(_voucherAccountImpl != address(0), "Invalid ERC6551 Account Impl address");

        __ReentrancyGuard_init();

        protocolFactoryAddress = _factoryAddress;
        dataRegistry = _dataRegistry;
        accountRegistry = _accountRegistry;
        voucherAccountImpl = _voucherAccountImpl;
        _owner = owner;
    }

    function setFactory(address _factory) public onlyOwner {
        protocolFactoryAddress = _factory;
    }

    function setDataRegistry(address _dataRegistry) public onlyOwner {
        dataRegistry = _dataRegistry;
    }

    function setAccountRegistry(address _accountRegistry) public onlyOwner {
        accountRegistry = _accountRegistry;
    }

    function setVoucherAccountImpl(address _voucherAccountImpl) public onlyOwner {
        voucherAccountImpl = _voucherAccountImpl;
    }

    // ====================================================
    //                    ERC721Receiver
    // ====================================================
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _prepareVestingSchedule(VestingSchedule[] memory schedules)
        internal
        pure
        returns (VestingSchedule[] memory)
    {
        for (uint256 i = 0; i < schedules.length; i++) {
            schedules[i].remainingAmount = schedules[i].amount;
        }
        return schedules;
    }

    function createVoucherCollection(
        address token,
        string calldata name,
        string calldata symbol,
        IFactory.CollectionSettings calldata settings
    ) public nonReentrant returns (address) {
        if (tokenNftMap[token] != address(0)) return tokenNftMap[token];

        address nft = IFactory(protocolFactoryAddress).createCollection(
            name, symbol, settings, IFactory.CollectionKind.ERC721Standard
        );

        tokenNftMap[token] = nft;
        _tokens.push(token);
        _nfts.push(nft);

        return nft;
    }

    function setX(address _token, address _nft) public onlyOwner {
        require(tokenNftMap[_token] == address(0));

        tokenNftMap[_token] = _nft;
        _tokens.push(_token);
        _nfts.push(_nft);
    }

    function removeX(address token) public onlyOwner {
        address nft = tokenNftMap[token];
        if (nft == address(0)) {
            return;
        }

        delete tokenNftMap[token];
        _removeToken(token);
        _removeNft(nft);
    }

    function getAllTokensNfts() public view returns (address[] memory tokens, address[] memory nfts) {
        return (_tokens, _nfts);
    }

    function getNftAddressFromMap(address tokenAddress) public view returns (address nftAddress) {
        if (tokenNftMap[tokenAddress] == address(0)) {
            revert("Not support tokenAddress ");
        }
        nftAddress = tokenNftMap[tokenAddress];
        return nftAddress;
    }

    function getTokenAddressFromNftAddress(address nftAddress) public view returns (address tokenAddress) {
        bool check = false;
        for (uint256 i = 0; i < _nfts.length; i++) {
            if (_nfts[i] == nftAddress) {
                tokenAddress = _tokens[i];
                check = true;
            }
        }
        if (!check) {
            revert("Not support nftAddress ");
        }
    }

    function create(address tokenAddress, Vesting memory vesting) public nonReentrant returns (address, uint256) {
        address nftAddress = getNftAddressFromMap(tokenAddress);
        vesting.schedules = _prepareVestingSchedule(vesting.schedules);
        vesting.fee.remainingFee = vesting.fee.totalFee;

        // mint new voucher
        uint256 tokenId = ICollection(nftAddress).safeMint(address(this));

        // create erc6551 token bound account
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
            dataRegistry,
            address(this),
            tokenAddress,
            vesting
        );
        address account = IAccountRegistry(accountRegistry).createAccount(
            voucherAccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
        );
        _tbaNftMap[nftAddress][tokenId] = account;

        // stake amount of token to erc6551 token bound account
        IERC20(tokenAddress).transferFrom(msg.sender, account, vesting.balance);
        require(IERC20(tokenAddress).balanceOf(account) == vesting.balance, "Stake voucher balance failed" );

        // grant writer role for account
        AccessControl(dataRegistry).grantRole(WRITER_ROLE, account);

        // transfer voucher to requester
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        // write to data registry
        IDynamic(dataRegistry).write(nftAddress, tokenId, keccak256(BALANCE_KEY), abi.encode(vesting.balance));

        emit VoucherCreated(msg.sender, tokenAddress, vesting.balance, nftAddress, tokenId);

        return (nftAddress, tokenId);
    }

    function createBatch(address tokenAddress, BatchVesting memory batch, uint96 royaltyRate)
        public
        nonReentrant
        returns (address, uint256, uint256)
    {
        address nftAddress = getNftAddressFromMap(tokenAddress);

        require(batch.vesting.balance * batch.quantity > 0, "Total balance must be greater than zero");
        require(batch.quantity == batch.tokenUris.length, "Length of tokenUris must be equal to quantity");

        batch.vesting.schedules = _prepareVestingSchedule(batch.vesting.schedules);
        batch.vesting.fee.remainingFee = batch.vesting.fee.totalFee;

        // mint nfts
        (uint256 startId, uint256 endId) = ICollection(nftAddress).safeMintBatchWithTokenUrisAndRoyalty(
            msg.sender, batch.tokenUris, msg.sender, royaltyRate
        );

        for (uint256 tokenId = startId; tokenId <= endId; tokenId++) {
            // create erc6551 token bound account
            bytes memory initData = abi.encodeWithSignature(
                "initialize(address,address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
                dataRegistry,
                address(this),
                tokenAddress,
                batch.vesting
            );
            address account = IAccountRegistry(accountRegistry).createAccount(
                voucherAccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
            );
            _tbaNftMap[nftAddress][tokenId] = account;

            // stake amount of token to erc6551 token bound account
            IERC20(tokenAddress).transferFrom(msg.sender, account, batch.vesting.balance);
            require(IERC20(tokenAddress).balanceOf(account) == batch.vesting.balance, "Stake voucher balance failed" );

            // grant writer role for account
            AccessControl(dataRegistry).grantRole(WRITER_ROLE, account);

            emit VoucherCreated(msg.sender, tokenAddress, batch.vesting.balance, nftAddress, tokenId);
        }

        // write data registry
        IDynamic(dataRegistry).writeBatch(
            nftAddress, startId, endId, keccak256(BALANCE_KEY), abi.encode(batch.vesting.balance)
        );

        return (nftAddress, startId, endId);
    }

    function createFor(address tokenAddress, Vesting memory vesting, address receiver) public nonReentrant returns (address, uint256) {
        require(receiver != address(0));

        address nftAddress = getNftAddressFromMap(tokenAddress);
        vesting.schedules = _prepareVestingSchedule(vesting.schedules);
        vesting.fee.remainingFee = vesting.fee.totalFee;

        // mint new voucher
        uint256 tokenId = ICollection(nftAddress).safeMint(address(this));

        // create erc6551 token bound account
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
            dataRegistry,
            address(this),
            tokenAddress,
            vesting
        );
        address account = IAccountRegistry(accountRegistry).createAccount(
            voucherAccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
        );
        _tbaNftMap[nftAddress][tokenId] = account;

        // stake amount of token to erc6551 token bound account
        IERC20(tokenAddress).transferFrom(msg.sender, account, vesting.balance);
        require(IERC20(tokenAddress).balanceOf(account) == vesting.balance, "Stake voucher balance failed" );

        // grant writer role for account
        AccessControl(dataRegistry).grantRole(WRITER_ROLE, account);

        // transfer voucher to requester
        IERC721(nftAddress).transferFrom(address(this), receiver, tokenId);

        // write to data registry
        IDynamic(dataRegistry).write(nftAddress, tokenId, keccak256(BALANCE_KEY), abi.encode(vesting.balance));

        emit VoucherCreated(receiver, tokenAddress, vesting.balance, nftAddress, tokenId);

        return (nftAddress, tokenId);
    }

    function createBatchFor(address tokenAddress, BatchVesting memory batch, uint96 royaltyRate, address receiver)
        public
        nonReentrant
        returns (address, uint256, uint256)
    {
        address nftAddress = getNftAddressFromMap(tokenAddress);

        require(batch.vesting.balance * batch.quantity > 0, "Total balance must be greater than zero");
        require(batch.quantity == batch.tokenUris.length, "Length of tokenUris must be equal to quantity");

        batch.vesting.schedules = _prepareVestingSchedule(batch.vesting.schedules);
        batch.vesting.fee.remainingFee = batch.vesting.fee.totalFee;

        // mint nfts
        (uint256 startId, uint256 endId) = ICollection(nftAddress).safeMintBatchWithTokenUrisAndRoyalty(
            receiver, batch.tokenUris, receiver, royaltyRate
        );

        for (uint256 tokenId = startId; tokenId <= endId; tokenId++) {
            // create erc6551 token bound account
            bytes memory initData = abi.encodeWithSignature(
                "initialize(address,address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
                dataRegistry,
                address(this),
                tokenAddress,
                batch.vesting
            );
            address account = IAccountRegistry(accountRegistry).createAccount(
                voucherAccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
            );
            _tbaNftMap[nftAddress][tokenId] = account;

            // stake amount of token to erc6551 token bound account
            IERC20(tokenAddress).transferFrom(msg.sender, account, batch.vesting.balance);
            require(IERC20(tokenAddress).balanceOf(account) == batch.vesting.balance, "Stake voucher balance failed" );

            // grant writer role for account
            AccessControl(dataRegistry).grantRole(WRITER_ROLE, account);

            emit VoucherCreated(receiver, tokenAddress, batch.vesting.balance, nftAddress, tokenId);
        }

        // write data registry
        IDynamic(dataRegistry).writeBatch(
            nftAddress, startId, endId, keccak256(BALANCE_KEY), abi.encode(batch.vesting.balance)
        );

        return (nftAddress, startId, endId);
    }

    function redeem(address nftAddress, uint256 tokenId, uint256 amount) public nonReentrant returns (bool) {
        address tba = _tbaNftMap[nftAddress][tokenId];

        // transfer fee for tba
        (uint256 balance,) = getDataBalanceAndSchedule(nftAddress, tokenId);
        (uint256 claimableAmount,,) = getClaimableAndSchedule(nftAddress, tokenId, block.timestamp, amount);
        uint256 transferAmount = amount > claimableAmount ? claimableAmount : amount;
        VestingFee memory fee = getDataFee(nftAddress, tokenId);

        uint256 feeAmount = Math.mulDiv(transferAmount, fee.remainingFee, balance);
        /**
         * Audit: if feeToken deducts fee-on-transfer, we will never get enough token 
         * 
         */
        if (feeAmount > 0 && fee.isFee == FEE_STATUS) {
            require(
                IERC20(fee.feeTokenAddress).transferFrom(msg.sender, address(this), feeAmount),
                "Voucher: Transfer fee failed"
            );
            require(IERC20(fee.feeTokenAddress).approve(address(tba), feeAmount), "Voucher: Approve fee for TBA failed");
        }

        // redeem voucher
        IVoucherAccount(tba).redeem(amount);

        emit VoucherRedeem(msg.sender, getTokenAddressFromNftAddress(nftAddress), transferAmount, nftAddress, tokenId);
        return true;
    }

    function isOwner(address redeemer, uint256 tokenId, address nftAddress) internal view returns (bool) {
        if (IERC721(nftAddress).ownerOf(tokenId) != redeemer) return false;
        return true;
    }

    function getClaimableAndSchedule(address nftAddress, uint256 tokenId, uint256 timestamp, uint256 amount)
        public
        view
        returns (uint256 claimableAmount, uint8 batchSize, VestingSchedule[] memory)
    {
        address tba = _tbaNftMap[nftAddress][tokenId];
        require(tba != address(0), "Voucher: voucher does not exists");
        return IVoucherAccount(tba).getClaimableAndSchedule(timestamp, amount);
    }

    function getVoucher(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256 totalAmount, uint256 claimable, VestingSchedule[] memory schedules, VestingFee memory fee)
    {
        (uint256 balance, VestingSchedule[] memory oschedules) = getDataBalanceAndSchedule(nftAddress, tokenId);
        (uint256 claimableAmount,,) = getClaimableAndSchedule(nftAddress, tokenId, block.timestamp, MAX_INT);

        fee = getDataFee(nftAddress, tokenId);

        return (balance, claimableAmount, oschedules, fee);
    }

    function getDataBalanceAndSchedule(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256, VestingSchedule[] memory)
    {
        address tba = _tbaNftMap[nftAddress][tokenId];
        require(tba != address(0), "Voucher: voucher does not exists");
        return IVoucherAccount(tba).getDataBalanceAndSchedule();
    }

    function getDataFee(address nftAddress, uint256 tokenId) public view returns (VestingFee memory fee) {
        address tba = _tbaNftMap[nftAddress][tokenId];
        require(tba != address(0), "Voucher: voucher does not exists");
        return IVoucherAccount(tba).getDataFee();
    }

    function getTokenBoundAccount(address nftAddress, uint256 tokenId) public view returns (address account) {
        return _tbaNftMap[nftAddress][tokenId];
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        (newImplementation);
        _onlyOwner();
    }

    function _removeToken(address token) private {
        for (uint256 idx = 0; idx < _tokens.length; idx++) {
            if (_tokens[idx] == token) {
                _tokens[idx] = _tokens[_tokens.length - 1];
                _tokens.pop();
                return;
            }
        }
    }

    function _removeNft(address nft) private {
        for (uint256 idx = 0; idx < _nfts.length; idx++) {
            if (_nfts[idx] == nft) {
                _nfts[idx] = _nfts[_nfts.length - 1];
                _nfts.pop();
                return;
            }
        }
    }
}
