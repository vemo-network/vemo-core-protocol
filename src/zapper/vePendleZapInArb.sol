// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import "erc6551/interfaces/IERC6551Executable.sol";
import "../interfaces/IWalletFactory.sol";

interface IVePENDLE is IERC20 {
    function increaseLockPositionAndBroadcast(uint128 additionalAmountToLock, uint128 newExpiry, uint256[] memory chains) external returns (uint128 newVeBalance);
    function increaseLockPosition(uint128 additionalAmountToLock, uint128 newExpiry) external returns (uint128 newVeBalance);
    function withdraw() external returns (uint128 amount);
}

interface INFTAccountDelegable {
    function delegate(address delegation, address receiver) external;
}

contract vePendleZapInArb is IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidAddress();
    
    address public  WALLET_FACTORY;
    IERC20 public constant PENDLE = IERC20(0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8);
    
    address public vemoDelegatee;

    constructor(
        address _walletFactory,
        address _vemoDelegatee
    ) {
        if (_walletFactory == address(0)) revert InvalidAddress();

        WALLET_FACTORY = _walletFactory;
        vemoDelegatee = _vemoDelegatee;
    }

    /**
     * @notice zap pendle into vependle containing in TBA
     * @param nftCollectionAddress  collection which mint TBA from
     * @param dlgCollectionAddress collection which mint delegatee from
     * @param amount Pendle amount - which approved for this contract
     * @param newExpiry  new lock time
     * @param chains  list of chain to broadcast new lock position
     * @return 
     */
    function zapInAndBroadcast(
        address nftCollectionAddress,
        address dlgCollectionAddress,
        uint256 amount,
        uint128 newExpiry,
        uint256[] memory chains
    ) public nonReentrant returns (uint256, address) {
        // create TBA
        (uint256 tokenId, address tba) = IWalletFactory(WALLET_FACTORY).create(nftCollectionAddress);

        if (dlgCollectionAddress != address(0)) {
            INFTAccountDelegable(payable(tba)).delegate(dlgCollectionAddress, vemoDelegatee);
        }

        if (amount > 0) {
            PENDLE.safeTransferFrom(msg.sender, tba, amount);
        }

        // transfer tokenId back to msg.sender
        IERC721(nftCollectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        
        return (tokenId, tba);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable{}

    fallback() external payable {}

}
