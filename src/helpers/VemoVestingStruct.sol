// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// data schemas
struct VestingSchedule {
    uint256 amount;
    uint8 vestingType; // linear: 1 | staged: 2
    uint8 linearType; // day: 1 | week: 2 | month: 3 | quarter: 4
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint8 isVested; // unvested: 0 | vested : 1 | vesting : 2
    uint256 remainingAmount;
}

struct VestingFee {
    uint8 isFee; // no-fee: 0 | fee : 1
    address feeTokenAddress;
    address receiverAddress;
    uint256 totalFee;
    uint256 remainingFee;
}

struct Vesting {
    uint256 balance;
    VestingSchedule[] schedules;
    VestingFee fee;
}

struct BatchVesting {
    Vesting vesting;
    uint256 quantity;
    string[] tokenUris;
}
