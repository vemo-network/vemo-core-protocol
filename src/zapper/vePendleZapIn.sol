// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import "erc6551/interfaces/IERC6551Executable.sol";
import "../interfaces/IWalletFactory.sol";

interface IVePENDLE is IERC20 {
    function increaseLockPositionAndBroadcast(uint128 additionalAmountToLock, uint128 newExpiry, uint256[] memory chains) external returns (uint128 newVeBalance);
    function increaseLockPosition(uint128 additionalAmountToLock, uint128 newExpiry) external returns (uint128 newVeBalance);
    function withdraw() external returns (uint128 amount);
}

contract vePendleZapIn is IERC721Receiver, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    error InvalidZapInAmount();
    error InvalidAddress();

    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }
    
    address public  WALLET_FACTORY;

    IERC20 public constant PENDLE = IERC20(0x808507121B80c02388fAd14726482e061B8da827);
    IVePENDLE public constant VE_PENDLE = IVePENDLE(0x4f30A9D41B80ecC5B94306AB4364951AE3170210);

    function initialize(
        address _owner,
        address _walletFactory
    ) public virtual initializer {
        if (_walletFactory == address(0)) revert InvalidAddress();

        __Ownable_init_unchained(_owner);
        WALLET_FACTORY = _walletFactory;
        stopped = false;
    }

    /**
     * zap pendle into vependle containing in TBA
     * @param nftCollectionAddress collection which mint TBA from
     * @param amount Pendle amount - which approved for this contract
     * @param newExpiry new lock time
     */
    function zapIn(
        address nftCollectionAddress,
        uint256 amount,
        uint128 newExpiry
    ) public returns (uint256, address) {
        if (amount == 0) revert InvalidZapInAmount();

        (uint256 tokenId, address tba) = IWalletFactory(WALLET_FACTORY).create(nftCollectionAddress);

        IERC20(PENDLE).safeTransferFrom(msg.sender, tba, amount);

        bytes memory approveCalldata = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(VE_PENDLE),
            amount
        );

        IERC6551Executable(payable(tba)).execute(address(PENDLE), 0, approveCalldata, 0);

        // Increase lock position using TBA
        bytes memory increaseLockCalldata = abi.encodeWithSignature(
            "increaseLockPosition(uint128,uint128)",
            amount,
            newExpiry
        );
        IERC6551Executable(payable(tba)).execute(address(VE_PENDLE), 0, increaseLockCalldata, 0);

        // transfer tokenId back to msg.sender
        IERC721(nftCollectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        return (tokenId, tba);
    }

    /**
     * zap pendle into vependle containing in TBA
     * @param nftCollectionAddress collection which mint TBA from
     * @param amount Pendle amount - which approved for this contract
     * @param newExpiry new lock time
     */
    function zapInAndBroadcast(
        address nftCollectionAddress,
        uint256 amount,
        uint128 newExpiry,
        uint256[] memory chains
    ) public returns (uint256, address) {
        if (amount == 0) revert InvalidAddress();

        (uint256 tokenId, address tba) = IWalletFactory(WALLET_FACTORY).create(nftCollectionAddress);

        IERC20(PENDLE).safeTransferFrom(msg.sender, tba, amount);

        bytes memory approveCalldata = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(VE_PENDLE),
            amount
        );

        IERC6551Executable(payable(tba)).execute(address(PENDLE), 0, approveCalldata, 0);

        // Increase lock position using TBA
        bytes memory increaseLockCalldata = abi.encodeWithSignature(
            "increaseLockPositionAndBroadcast(uint128,uint128,uint256[])",
            amount,
            newExpiry,
            chains
        );
        IERC6551Executable(payable(tba)).execute(address(VE_PENDLE), 0, increaseLockCalldata, 0);

        // transfer tokenId back to msg.sender
        IERC721(nftCollectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        
        return (tokenId, tba);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner virtual override {
        (newImplementation);
    }

    receive() external payable{}

    fallback() external payable {}

}
