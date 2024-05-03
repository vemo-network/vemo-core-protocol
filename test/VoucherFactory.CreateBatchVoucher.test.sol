// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./VoucherFactory.base.sol";

contract FactoryCreateBatchTest is Test, VoucherFactoryBaseTest {
    function testCreateBatchAndRedeem() public {
        // create
        VestingSchedule memory schedule = VestingSchedule({
            amount: 100,
            vestingType: 1, // linear: 1 | staged: 2
            linearType: 1, // day: 1 | week: 2 | month: 3 | quarter: 4
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + 1,
            isVested: 2, // unvested: 0 | vested : 1 | vesting : 2
            remainingAmount: 0
        });
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;

        VestingFee memory fee = VestingFee({
            isFee: 1, // no-fee: 0 | fee : 1
            feeTokenAddress: address(usdc),
            receiverAddress: feeReceiver,
            totalFee: 200,
            remainingFee: 200
        });

        Vesting memory vesting = Vesting({balance: 100, schedules: schedules, fee: fee});

        vm.startPrank(user);
        usdt.mint(user, 100);
        usdt.approve(address(voucherFactory), 100);
        string[] memory tokenUris = new string[](1);
        tokenUris[0] = "tokenUri";
        (address nftAddress, uint256 tokenId,) =
            voucherFactory.createBatch(address(usdt), BatchVesting({vesting: vesting, quantity: 1, tokenUris: tokenUris}), 0, user);
        vm.stopPrank();

        VoucherAccount tba = VoucherAccount(payable(voucherFactory.getTokenBoundAccount(nftAddress, tokenId)));

        assertEq(tba.tokenAddress(), address(usdt));
        assertEq(address(nft), nftAddress);
        assertEq(user, nft.ownerOf(tokenId));

        bytes memory remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        uint256 remaining = abi.decode(remainingValue, (uint256));
        assertEq(remaining, 100);

        address voucherAccount = voucherFactory.getTokenBoundAccount(nftAddress, tokenId);
        address payable pAccount = payable(voucherAccount);
        (uint256 accountChainId, address accountNftAddress, uint256 accountTokenId) = IERC6551Account(pAccount).token();

        assertEq(block.chainid, accountChainId);
        assertEq(nftAddress, accountNftAddress);
        assertEq(tokenId, accountTokenId);
        assertEq(0, usdt.balanceOf(user));
        assertEq(100, usdt.balanceOf(voucherAccount));

        // redeem
        skip(1000);
        usdc.mint(user, 200);
        vm.startPrank(user);
        usdc.approve(address(voucherFactory), 200);
        voucherFactory.redeem(nftAddress, tokenId, 50);
        vm.stopPrank();

        assertEq(50, usdt.balanceOf(voucherAccount));
        assertEq(50, usdt.balanceOf(user));
        assertEq(100, usdc.balanceOf(user));
        assertEq(100, usdc.balanceOf(feeReceiver));

        remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        remaining = abi.decode(remainingValue, (uint256));

        assertEq(remaining, 50);
    }
}
