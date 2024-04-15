// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IDynamic.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IVemoVoucher.sol";
import "./interfaces/IVemoAccount.sol";
import "./interfaces/IERC6551Registry.sol";

import "./Common.sol";

contract Voucher is IERC721Receiver, IVemoVoucher, UUPSUpgradeable {
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

    uint8 private lock;

    modifier noReentrance() {
        require(lock == 0, "Contract is locking");
        lock = 1;
        _;
        lock = 0;
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

    address private _protocolFactoryAddress;
    address private _dataRegistry;
    address private _erc6551Registry;
    address private _erc6551AccountImpl;

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
        address factoryAddress,
        address dataRegistry,
        address erc6551Registry,
        address erc6551AccountImpl
    ) public virtual initializer {
        require(factoryAddress != address(0), "Invalid ERC20 token address");
        require(dataRegistry != address(0), "Invalid Data registry address");
        require(erc6551Registry != address(0), "Invalid ERC6551 registry address");
        require(erc6551AccountImpl != address(0), "Invalid ERC6551 Account Impl address");
        lock = 0;
        _protocolFactoryAddress = factoryAddress;
        _dataRegistry = dataRegistry;
        _erc6551Registry = erc6551Registry;
        _erc6551AccountImpl = erc6551AccountImpl;
        _owner = owner;
    }

    function setFactory(address factory) public onlyOwner {
        _protocolFactoryAddress = factory;
    }

    function setDataRegistry(address dataRegistry) public onlyOwner {
        _dataRegistry = dataRegistry;
    }

    function setERC6551Registry(address erc6551Registry) public onlyOwner {
        _erc6551Registry = erc6551Registry;
    }

    function setERC6551AccountImpl(address erc6551AccountImpl) public onlyOwner {
        _erc6551AccountImpl = erc6551AccountImpl;
    }

    // ====================================================
    //                    ERC721Receiver
    // ====================================================
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateVestingScheduleBeforeCreate(VestingSchedule[] memory schedules)
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
    ) public noReentrance returns (bool) {
        address nft = IFactory(_protocolFactoryAddress).createCollection(
            name, symbol, settings, IFactory.CollectionKind.ERC721Standard
        );
        if (tokenNftMap[token] == address(0)) {
            tokenNftMap[token] = nft;
            _tokens.push(token);
            _nfts.push(nft);
        }
        return true;
    }

    function setX(address _token, address _nft) public onlyOwner {
        if (tokenNftMap[_token] == address(0)) {
            // Update the value at this address
            tokenNftMap[_token] = _nft;
            _tokens.push(_token);
            _nfts.push(_nft);
        }
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

    function getNftAddressFromMap(address tokenAddress) internal view returns (address nftAddress) {
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

    function create(address tokenAddress, Vesting memory vesting) public noReentrance returns (address, uint256) {
        address nftAddress = getNftAddressFromMap(tokenAddress);
        require(
            isQualifiedCreator(tokenAddress, msg.sender, vesting.balance),
            "Requester must approve sufficient amount to create voucher"
        );
        vesting.schedules = updateVestingScheduleBeforeCreate(vesting.schedules);
        vesting.fee.remainingFee = vesting.fee.totalFee;

        // mint new voucher
        uint256 tokenId = ICollection(nftAddress).safeMint(address(this));

        // create erc6551 token bound account
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
            _dataRegistry,
            address(this),
            vesting
        );
        address account = IERC6551Registry(_erc6551Registry).createAccount(
            _erc6551AccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
        );
        _tbaNftMap[nftAddress][tokenId] = account;

        // stake amount of token to erc6551 token bound account
        require(IERC20(tokenAddress).transferFrom(msg.sender, account, vesting.balance), "Stake voucher balance failed");

        // grant writer role for account
        AccessControl(_dataRegistry).grantRole(WRITER_ROLE, account);

        // transfer voucher to requester
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        // write to data registry
        IDynamic(_dataRegistry).write(nftAddress, tokenId, keccak256(BALANCE_KEY), abi.encode(vesting.balance));

        emit VoucherCreated(msg.sender, tokenAddress, vesting.balance, nftAddress, tokenId);

        return (nftAddress, tokenId);
    }

    function createBatch(address tokenAddress, BatchVesting memory batch, uint96 royaltyRate)
        public
        noReentrance
        returns (address, uint256, uint256)
    {
        address nftAddress = getNftAddressFromMap(tokenAddress);

        require(batch.vesting.balance * batch.quantity > 0, "Total balance must be greater than zero");
        require(batch.quantity == batch.tokenUris.length, "Length of tokenUris must be equal to quantity");
        
        batch.vesting.schedules = updateVestingScheduleBeforeCreate(batch.vesting.schedules);
        batch.vesting.fee.remainingFee = batch.vesting.fee.totalFee;

        require(
            isQualifiedCreator(tokenAddress, msg.sender, batch.vesting.balance * batch.quantity),
            "Requester must approve sufficient amount to create voucher"
        );

        // mint nfts
        (uint256 startId, uint256 endId) =
            ICollection(nftAddress).safeMintBatchWithTokenUrisAndRoyalty(msg.sender, batch.tokenUris, msg.sender, royaltyRate);

        for (uint256 tokenId = startId; tokenId <= endId; tokenId++) {
            // create erc6551 token bound account
            bytes memory initData = abi.encodeWithSignature(
                "initialize(address,address,(uint256,(uint256,uint8,uint8,uint256,uint256,uint8,uint256)[],(uint8,address,address,uint256,uint256)))",
                _dataRegistry,
                address(this),
                batch.vesting
            );
            address account = IERC6551Registry(_erc6551Registry).createAccount(
                _erc6551AccountImpl, bytes32(_salt++), block.chainid, nftAddress, tokenId, initData
            );
            _tbaNftMap[nftAddress][tokenId] = account;

            // stake amount of token to erc6551 token bound account
            require(
                IERC20(tokenAddress).transferFrom(msg.sender, account, batch.vesting.balance),
                "Stake voucher balance failed"
            );

            // grant writer role for account
            AccessControl(_dataRegistry).grantRole(WRITER_ROLE, account);

            emit VoucherCreated(msg.sender, tokenAddress, batch.vesting.balance, nftAddress, tokenId);
        }

        // write data registry
        IDynamic(_dataRegistry).writeBatch(
            nftAddress, startId, endId, keccak256(BALANCE_KEY), abi.encode(batch.vesting.balance)
        );

        return (nftAddress, startId, endId);
    }

    function isQualifiedCreator(address tokenAddress, address creator, uint256 amount) internal view returns (bool) {
        if (IERC20(tokenAddress).allowance(creator, address(this)) < amount) {
            return false;
        }
        return true;
    }

    function redeem(address nftAddress, uint256 tokenId, uint256 amount) public noReentrance returns (bool) {
        require(isOwner(msg.sender, tokenId, nftAddress), "Redeemer must be true owner of voucher");
        address tba = _tbaNftMap[nftAddress][tokenId];

        // transfer fee for tba
        (uint256 balance,) = getDataBalanceAndSchedule(nftAddress, tokenId);
        (uint256 claimableAmount,,) = getClaimableAndSchedule(nftAddress, tokenId, block.timestamp, amount);
        uint256 transferAmount = amount > claimableAmount ? claimableAmount : amount;
        VestingFee memory fee = getDataFee(nftAddress, tokenId);

        uint256 feeAmount = Math.mulDiv(transferAmount, fee.remainingFee, balance);
        if (feeAmount > 0 && fee.isFee == FEE_STATUS) {
            require(
                IERC20(fee.feeTokenAddress).transferFrom(msg.sender, address(this), feeAmount),
                "Voucher: Transfer fee failed"
            );
            require(IERC20(fee.feeTokenAddress).approve(address(tba), feeAmount), "Voucher: Approve fee for TBA failed");
        }

        // redeem voucher
        IVemoAccount(tba).redeem(amount);

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
        return IVemoAccount(tba).getClaimableAndSchedule(timestamp, amount);
    }

    function getVoucher(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256 totalAmount, uint256 claimable, VestingSchedule[] memory schedules, VestingFee memory fee)
    {
        (uint256 balance, VestingSchedule[] memory oschedules) = getDataBalanceAndSchedule(nftAddress, tokenId);
        (uint256 claimableAmount, , ) =
            getClaimableAndSchedule(nftAddress, tokenId, block.timestamp, MAX_INT);

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
        return IVemoAccount(tba).getDataBalanceAndSchedule();
    }

    function getDataFee(address nftAddress, uint256 tokenId) public view returns (VestingFee memory fee) {
        address tba = _tbaNftMap[nftAddress][tokenId];
        require(tba != address(0), "Voucher: voucher does not exists");
        return IVemoAccount(tba).getDataFee();
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
