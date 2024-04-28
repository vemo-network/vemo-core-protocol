// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/DataRegistryV2.sol";
import "../src/VoucherAccount.sol";
import "../src/AccountRegistry.sol";
import "../src/VoucherFactory.sol";
import "../src/Common.sol";

import "../src/interfaces/IVoucherFactory.sol";
import "../src/interfaces/IVoucherAccount.sol";
import "../src/helpers/DataStruct.sol";

import "./mock/NFT.sol";
import "./mock/USDT.sol";
import "./mock/USDC.sol";
import "./mock/Factory.sol";

contract CreateBatchTest is Test {
    uint256 defaultAdminPrivateKey = 1;
    uint256 userPrivateKey = 2;
    uint256 feeReceiverPrivateKey = 3;
    address defaultAdmin = vm.addr(defaultAdminPrivateKey);
    address user = vm.addr(userPrivateKey);
    address feeReceiver = vm.addr(feeReceiverPrivateKey);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant WRITER_ROLE = keccak256("WRITER_ROLE");
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes private constant BALANCE_KEY = "BALANCE";

    VoucherFactory voucher;
    Factory factory = new Factory();
    NFT nft;
    DataRegistryV2 dataRegistry;
    AccountRegistry accountRegistry = new AccountRegistry();
    VoucherAccount accountImpl = new VoucherAccount();
    address account;
    USDT usdt = new USDT();
    USDC usdc = new USDC();

    function setUp() public {
        nft = new NFT(defaultAdmin);
        dataRegistry = new DataRegistryV2();
        dataRegistry.initialize(
            defaultAdmin, address(factory), "", DataRegistrySettings({disableComposable: true, disableDerivable: true})
        );
        address proxy = Upgrades.deployUUPSProxy(
            "VoucherFactory.sol:VoucherFactory",
            abi.encodeCall(
                VoucherFactory.initialize,
                (defaultAdmin, address(factory), address(dataRegistry), address(accountRegistry), address(accountImpl))
            )
        );
        voucher = VoucherFactory(proxy);
        vm.startPrank(defaultAdmin);
        nft.grantRole(MINTER_ROLE, address(voucher));
        dataRegistry.grantRole(DEFAULT_ADMIN_ROLE, address(voucher));
        dataRegistry.grantRole(WRITER_ROLE, address(voucher));
        vm.stopPrank();
    }

    function testCreateBatchAndRedeem() public {
        vm.startPrank(defaultAdmin);
        voucher.setX(address(usdt), address(nft));
        vm.stopPrank();

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
        usdt.approve(address(voucher), 100);
        string[] memory tokenUris = new string[](1);
        tokenUris[0] = "tokenUri";
        (address nftAddress, uint256 tokenId,) =
            voucher.createBatch(address(usdt), BatchVesting({vesting: vesting, quantity: 1, tokenUris: tokenUris}), 0);
        vm.stopPrank();

        VoucherAccount tba = VoucherAccount(payable(voucher.getTokenBoundAccount(nftAddress, tokenId)));
        assertEq(tba.tokenAddress(), address(usdt));
        
        assertEq(address(nft), nftAddress);
        assertEq(user, nft.ownerOf(tokenId));

        bytes memory remainingValue = dataRegistry.read(nftAddress, tokenId, keccak256(BALANCE_KEY));
        uint256 remaining = abi.decode(remainingValue, (uint256));
        assertEq(remaining, 100);

        address voucherAccount = voucher.getTokenBoundAccount(nftAddress, tokenId);
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
        usdc.approve(address(voucher), 200);
        voucher.redeem(nftAddress, tokenId, 50);
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
