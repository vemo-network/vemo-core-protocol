// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IFactory.sol";
import "../Common.sol";

interface IVemoVoucher {
    event VoucherRedeem(
        address indexed account,
        address indexed currency,
        uint256 claimedAmount,
        address indexed nftCollection,
        uint256 tokenId
    );

    event VoucherSplit(address indexed nftCollection, uint256 tokenId, uint256[] percentageBps, uint256[] newTokenIds);

    function getTokenAddressFromNftAddress(address nftAddress) external returns (address tokenAddress);

    function getDataBalanceAndSchedule(address nftAddress, uint256 tokenId)
        external
        returns (uint256, VestingSchedule[] memory);

    function getDataFee(address nftAddress, uint256 tokenId) external returns (VestingFee memory fee);

    function getClaimableAndSchedule(address nftAddress, uint256 tokenId, uint256 timestamp, uint256 _amount)
        external
        returns (uint256 claimableAmount, uint8 batchSize, VestingSchedule[] memory);

    function create(address tokenAddress, Vesting memory vesting)
        external
        returns (address nftAddress, uint256 tokenId);

    function createBatch(address tokenAddress, BatchVesting memory batch, uint96 royaltyRate)
        external
        returns (address nftAddress, uint256 startId, uint256 endId);

    function redeem(address nftAddress, uint256 tokenId, uint256 _amount) external returns (bool);
}
