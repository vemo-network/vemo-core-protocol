// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../helpers/VemoVestingStruct.sol";
interface IVoucherAccount {
    function redeem(uint256 amount) external;

    function getDataBalanceAndSchedule() external view returns (uint256, VestingSchedule[] memory);

    function getDataFee() external view returns (VestingFee memory fee);

    function getClaimableAndSchedule(uint256 timestamp, uint256 _amount)
        external view
        returns (uint256 claimableAmount, uint8 batchSize, VestingSchedule[] memory);
}
