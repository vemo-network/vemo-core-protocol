// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./VoucherFactory.base.sol";

contract FactoryCreateForTest is Test, VoucherFactoryBaseTest {
    address user1 = vm.addr(4);
    USDT lockToken = new USDT();

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

    function testNewAutoURICollection() public {
        address nft = voucherFactory.createAutoURIVoucherCollection(
            address(lockToken),
            address(globalDescriptor)
        );
        
        assertEq(voucherFactory.getNftAddressFromMap(address(lockToken)), nft);
        vm.stopPrank();

        // could not create same nft with same x
        vm.startPrank(vm.addr(999998));
        address _nft = voucherFactory.createAutoURIVoucherCollection(
            address(lockToken),
            address(globalDescriptor)
        );

        assertEq(_nft, nft);
        assertEq(
            ERC721(nft).name(),
            "USDT Smart Voucher"
        );
        assertEq(
            ERC721(nft).symbol(),
            "USDTSV"
        );

        vm.stopPrank();
    }

    function testCreateVoucher() public {
        USDT lockToken = new USDT();
        address autoURICollection = voucherFactory.createAutoURIVoucherCollection(
            address(lockToken),
            address(globalDescriptor)
        );

        uint256 VESTING_BALANCE = 100_000_000;
        VestingSchedule[] memory schedules = new VestingSchedule[](1);
        schedules[0] = schedule;
        Vesting memory vesting = Vesting({balance: VESTING_BALANCE, schedules: schedules, fee: fee});

        vm.startPrank(defaultAdmin);
        vm.expectRevert();
        (address nftAddress, uint256 tokenId) = voucherFactory.create(address(lockToken), vesting);
        vm.stopPrank();

        vm.startPrank(user);
        lockToken.mint(user, VESTING_BALANCE);
        lockToken.approve(address(voucherFactory), VESTING_BALANCE);
        (nftAddress, tokenId) = voucherFactory.create(address(lockToken), vesting);
        vm.stopPrank();

        // make sure we store the correct vesting data in ERC6551
        VoucherAccount tba = VoucherAccount(payable(voucherFactory.getTokenBoundAccount(nftAddress, tokenId)));
        assertEq(tba.tokenAddress(), address(lockToken));

        VestingSchedule memory _schedule = tba.schedules(0);
        assertEq(schedule.amount, _schedule.amount);
        assertEq(schedule.vestingType, _schedule.vestingType);
        assertEq(schedule.linearType, _schedule.linearType);
        assertEq(schedule.startTimestamp, _schedule.startTimestamp);
        assertEq(schedule.endTimestamp, _schedule.endTimestamp);

        assertEq(address(autoURICollection), nftAddress);
        assertEq(user, ERC721(autoURICollection).ownerOf(tokenId));

        console.log(ERC721(autoURICollection).tokenURI(tokenId));

        // check lockToken balance
        bytes memory remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        uint256 remaining = abi.decode(remainingValue, (uint256));
        assertEq(remaining, VESTING_BALANCE);

        address voucherAccount = voucherFactory.getTokenBoundAccount(nftAddress, tokenId);
        address payable pAccount = payable(voucherAccount);
        (uint256 accountChainId, address accountNftAddress, uint256 accountTokenId) = IERC6551Account(pAccount).token();
        assertEq(block.chainid, accountChainId);
        assertEq(nftAddress, accountNftAddress);
        assertEq(tokenId, accountTokenId);
        // assertEq(0, lockToken.balanceOf(user));
        // assertEq(VESTING_BALANCE, lockToken.balanceOf(voucherAccount));
    }

}
