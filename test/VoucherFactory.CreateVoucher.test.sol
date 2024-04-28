// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./VoucherFactory.base.sol";

contract FactoryCreateTest is Test, VoucherFactoryBaseTest {
    address user1 = vm.addr(4);

    // create
    VestingSchedule schedule = VestingSchedule({
        amount: 100,
        vestingType: 1, // linear: 1 | staged: 2
        linearType: 1, // day: 1 | week: 2 | month: 3 | quarter: 4
        startTimestamp: block.timestamp,
        endTimestamp: block.timestamp + 1,
        isVested: 2, // unvested: 0 | vested : 1 | vesting : 2
        remainingAmount: 0
    });

    VestingFee fee = VestingFee({
        isFee: 1, // no-fee: 0 | fee : 1
        feeTokenAddress: address(usdc),
        receiverAddress: feeReceiver,
        totalFee: 200,
        remainingFee: 200
    });

    function testSingleCreate() public {
        uint256 VESTING_BALANCE = 100_000_000;
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;
        Vesting memory vesting = Vesting({balance: VESTING_BALANCE, schedules: schedules, fee: fee});

        vm.startPrank(defaultAdmin);
        vm.expectRevert();
        (address nftAddress, uint256 tokenId) = voucherFactory.create(address(usdt), vesting);
        vm.stopPrank();

        vm.startPrank(user);
        usdt.mint(user, VESTING_BALANCE);
        usdt.approve(address(voucherFactory), VESTING_BALANCE);
        (nftAddress, tokenId) = voucherFactory.create(address(usdt), vesting);
        vm.stopPrank();

        // make sure we store the correct vesting data in ERC6551
        VoucherAccount tba = VoucherAccount(payable(voucherFactory.getTokenBoundAccount(nftAddress, tokenId)));
        assertEq(tba.tokenAddress(), address(usdt));

        VestingSchedule memory _schedule = tba.schedules(0);
        assertEq(schedule.amount, _schedule.amount);
        assertEq(schedule.vestingType, _schedule.vestingType);
        assertEq(schedule.linearType, _schedule.linearType);
        assertEq(schedule.startTimestamp, _schedule.startTimestamp);
        assertEq(schedule.endTimestamp, _schedule.endTimestamp);
        assertEq(_schedule.isVested, 2); // vesting
        assertEq(schedule.amount, _schedule.remainingAmount);

        assertEq(address(nft), nftAddress);
        assertEq(user, nft.ownerOf(tokenId));

        // check usdt balance
        bytes memory remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        uint256 remaining = abi.decode(remainingValue, (uint256));
        assertEq(remaining, VESTING_BALANCE);

        address voucherAccount = voucherFactory.getTokenBoundAccount(nftAddress, tokenId);
        address payable pAccount = payable(voucherAccount);
        (uint256 accountChainId, address accountNftAddress, uint256 accountTokenId) = IERC6551Account(pAccount).token();
        assertEq(block.chainid, accountChainId);
        assertEq(nftAddress, accountNftAddress);
        assertEq(tokenId, accountTokenId);
        assertEq(0, usdt.balanceOf(user));
        assertEq(VESTING_BALANCE, usdt.balanceOf(voucherAccount));
    }

    function testMultipleCreate() public {}

    function testSingleCreateAndRedeemThruVoucher() public {
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;
        Vesting memory vesting = Vesting({balance: 100, schedules: schedules, fee: fee});

        vm.startPrank(user);
        usdt.mint(user, 100);
        usdt.approve(address(voucherFactory), 100);
        (address nftAddress, uint256 tokenId) = voucherFactory.create(address(usdt), vesting);
        vm.stopPrank();

        address voucherAccount = voucherFactory.getTokenBoundAccount(nftAddress, tokenId);

        skip(1000);
        usdc.mint(user, 200);

        // redeem without authorization
        vm.startPrank(user1);
        usdc.approve(address(voucherFactory), 200);
        vm.expectRevert();
        voucherFactory.redeem(nftAddress, tokenId, 50);
        vm.stopPrank();

        // redeem with authorization
        vm.startPrank(user);
        usdc.approve(address(voucherFactory), 200);
        voucherFactory.redeem(nftAddress, tokenId, 50);
        vm.stopPrank();

        assertEq(50, usdt.balanceOf(voucherAccount));
        assertEq(50, usdt.balanceOf(user));
        assertEq(100, usdc.balanceOf(user));
        assertEq(100, usdc.balanceOf(feeReceiver));

        bytes memory remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        uint256 remaining = abi.decode(remainingValue, (uint256));
        assertEq(remaining, 50);
    }

    function testSingleCreateAndRedeemThruVoucherAccount() public {
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;
        Vesting memory vesting = Vesting({balance: schedule.amount, schedules: schedules, fee: fee});

        vm.startPrank(user);

        usdt.mint(user, schedule.amount);
        usdt.approve(address(voucherFactory), schedule.amount);
        (address nftAddress, uint256 tokenId) = voucherFactory.create(address(usdt), vesting);

        VoucherAccount tba = VoucherAccount(payable(voucherFactory.getTokenBoundAccount(nftAddress, tokenId)));
        vm.stopPrank();

        assertEq(0, usdt.balanceOf(user));

        // skipp to the end time
        skip(100_000);

        // try to claim the half
        vm.startPrank(user1);
        usdc.mint(user1, fee.totalFee / 2);
        usdc.approve(address(tba), fee.totalFee / 2);
        tba.redeem(schedule.amount / 2);
        vm.stopPrank();

        // validate the receiver
        assertEq(schedule.amount / 2, usdt.balanceOf(user));
        assertEq(0, usdc.balanceOf(user1));
        assertEq(fee.totalFee / 2, usdc.balanceOf(feeReceiver));

        VestingFee memory __fee = tba.getDataFee();
        assertEq(__fee.remainingFee, fee.totalFee / 2);

        // claim the second half
        vm.startPrank(user1);
        usdc.mint(user1, fee.totalFee / 2);
        usdc.approve(address(tba), fee.totalFee / 2);
        tba.redeem(schedule.amount / 2);
        vm.stopPrank();

        // validate the receiver
        assertEq(schedule.amount, usdt.balanceOf(user));
        assertEq(0, usdc.balanceOf(user1));
        assertEq(fee.totalFee, usdc.balanceOf(feeReceiver));

        __fee = tba.getDataFee();
        assertEq(__fee.remainingFee, 0);
    }
}
