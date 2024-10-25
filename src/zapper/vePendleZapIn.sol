// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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

contract vePendleZapIn is IERC721Receiver {
    using SafeERC20 for IERC20;

    error InvalidAddress();

    // ether IERC20(0x808507121B80c02388fAd14726482e061B8da827)
    // arb IERC20(0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8);
    IERC20 public immutable PENDLE;
    IVePENDLE public constant VE_PENDLE = IVePENDLE(0x4f30A9D41B80ecC5B94306AB4364951AE3170210);

    address public immutable WALLET_FACTORY;

    constructor(
        address _walletFactory,
        address _pendle
    ) {
        if (_walletFactory == address(0)) revert InvalidAddress();

        WALLET_FACTORY = _walletFactory;
        PENDLE = IERC20(_pendle);
    }

    /**
     * @notice zap pendle into vependle containing in TBA
     * during the process, whatever steps which need execute 
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
        address vemoDelegatee,
        uint256 amount,
        uint128 newExpiry,
        uint256[] memory chains
    ) payable public returns (uint256, address) {
        (uint256 tokenId, address tba) = IWalletFactory(WALLET_FACTORY).create(nftCollectionAddress);
        
        if (msg.value > 0) {
            tba.call{value: msg.value}("");
        }

        if (dlgCollectionAddress != address(0)) {
            INFTAccountDelegable(payable(tba)).delegate(dlgCollectionAddress, vemoDelegatee);
        }

        if (amount == 0) {
            // transfer tokenId back to msg.sender
            IERC721(nftCollectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);
            return (tokenId, tba);
        }

        PENDLE.safeTransferFrom(msg.sender, tba, amount);

        if (newExpiry == 0) {
            // transfer tokenId back to msg.sender
            IERC721(nftCollectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);
            return (tokenId, tba);
        }

        /**
         * do approve and stake into vependle
         */
        bytes memory approveCalldata = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(VE_PENDLE),
            amount
        );

        IERC6551Executable(payable(tba)).execute(address(PENDLE), 0, approveCalldata, 0);

        // Increase lock position using TBA
        bytes memory increaseLockCalldata;
        
        if (chains.length > 0) {
            increaseLockCalldata = abi.encodeWithSignature(
                "increaseLockPositionAndBroadcast(uint128,uint128,uint256[])",
                amount,
                newExpiry,
                chains
            );
        } else {
            // Increase lock position using TBA
            increaseLockCalldata = abi.encodeWithSignature(
                "increaseLockPosition(uint128,uint128)",
                amount,
                newExpiry
            );
        }

        IERC6551Executable(payable(tba)).execute(address(VE_PENDLE), 0, increaseLockCalldata, 0);

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
