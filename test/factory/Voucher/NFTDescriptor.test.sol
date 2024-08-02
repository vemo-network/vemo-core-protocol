// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../../src/helpers/NFTDescriptor/NFTDescriptor.sol";
import "../../mock/USDT.sol";

contract NFTDescriptorTest is Test {
    NFTDescriptor globalDescriptor;
    USDT usdt = new USDT();

    function setUp() public {
        globalDescriptor = NFTDescriptor(Upgrades.deployUUPSProxy(
            "NFTDescriptor.sol:NFTDescriptor",
            abi.encodeCall(
                NFTDescriptor.initialize,
                (address(this))
            )
        ));

        vm.stopPrank();
    }

    function contains(string memory what, string memory where) pure private returns(bool found) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        require(whereBytes.length >= whatBytes.length);

        found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
    }

    function testGenerateDescriptionPart() public {
        VestingSchedule memory schedule = VestingSchedule({
            amount: 100,
            vestingType: 1, // linear: 1 | staged: 2
            linearType: 1, // day: 1 | week: 2 | month: 3 | quarter: 4
            startTimestamp: 1722583188,
            endTimestamp: 1722583188 + 86400,
            isVested: 2, // unvested: 0 | vested : 1 | vesting : 2
            remainingAmount: 0
        });
        
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;

        INFTDescriptor.ConstructTokenURIParams memory params = INFTDescriptor.ConstructTokenURIParams({
            nftId: 1,
            balance: 99999999999,
            voucherToken: address(usdt),
            nftAddress: address(this),
            collectionName: "NFTDescriptorTest",
            schedules: schedules
        });

        string memory description = globalDescriptor.generateDescriptionPart(params);
        assertEq(
            contains("Batch 1: 100% daily linear release in 1 day starting at", description),
            true
        );
        
        VestingSchedule[] memory schedules2 = new VestingSchedule[](2);
        schedules2[0] = VestingSchedule({
            amount: 100,
            vestingType: 1, // linear: 1 | staged: 2
            linearType: 1, // day: 1 | week: 2 | month: 3 | quarter: 4
            startTimestamp: 1722583188,
            endTimestamp: 1722583188 + 86400,
            isVested: 2, // unvested: 0 | vested : 1 | vesting : 2
            remainingAmount: 0
        });

        schedules2[1] = VestingSchedule({
            amount: 1000,
            vestingType: 2, // linear: 1 | staged: 2
            linearType: 2, // day: 1 | week: 2 | month: 3 | quarter: 4
            startTimestamp: 1722583188,
            endTimestamp: 1722583188 + 86400*14,
            isVested: 2, // unvested: 0 | vested : 1 | vesting : 2
            remainingAmount: 0
        });
        params.schedules = schedules2;
        description = globalDescriptor.generateDescriptionPart(params);

        assertEq(
            contains("Batch 1: 9% daily linear release in 1 day starting at", description),
            true
        );

        assertEq(
            contains("Batch 2: 90% weekly staged release in 2 weeks starting at", description),
            true
        );

        vm.stopPrank();
    }

}
