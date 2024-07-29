// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../VemoVestingStruct.sol";

interface INFTDescriptor {
    struct ConstructTokenURIParams {
        uint256 nftId;
        uint256 balance;
        address voucherToken;
        address nftAddress;
        string collectionName;
        VestingSchedule[] schedules;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) external pure returns (string memory);
}
