// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Executable.sol";
import "./interfaces/IVemoAccount.sol";
import "./interfaces/IDynamic.sol";
import "./interfaces/IVemoVoucher.sol";

import "./Common.sol";

contract ERC6551Account is IERC165, IERC1271, IERC6551Account, IERC6551Executable, IVemoAccount {
    uint256 public _state;

    // constants definition
    uint8 private constant LINEAR_VESTING_TYPE = 1;
    uint8 private constant STAGED_VESTING_TYPE = 2;

    uint8 private constant SECOND_LINEAR_VESTING_TYPE = 6;
    uint8 private constant DAILY_LINEAR_VESTING_TYPE = 1;
    uint8 private constant WEEKLY_LINEAR_VESTING_TYPE = 2;
    uint8 private constant MONTHLY_LINEAR_VESTING_TYPE = 3;
    uint8 private constant QUARTERLY_LINEAR_VESTING_TYPE = 4;
    uint8 private constant YEARLY_LINEAR_VESTING_TYPE = 5;

    bytes private constant BALANCE_KEY = "BALANCE";

    uint8 private constant REDEEM_BATCH_SIZE = 10; // maximum number of schedules to be redeemed onetime

    uint8 private constant FEE_STATUS = 1;

    uint8 private constant UNVESTED_STATUS = 0;
    uint8 private constant VESTED_STATUS = 1;
    uint8 private constant VESTING_STATUS = 2; // this status is specific for linear vesting type

    address private _dataRegistry;
    address private _voucher;
    uint256 public _balance;
    VestingFee private _fee;
    VestingSchedule[] private _schedules;
    address public tokenAddress;

    /**
     * @dev
     * The function for initializing immutable data: _dataRegistry
     * This function MUST be call once and only once right after the ERC6551Account is created in the same transaction
     */
    function initialize(address dataRegistry, address voucher, address _tokenAddress, Vesting calldata vesting) external {
        require(_voucher == address(0), "ERC6551Account: initialize() can execute only once");
        _dataRegistry = dataRegistry;
        _voucher = voucher;
        _balance = vesting.balance;
        tokenAddress = _tokenAddress;
        if (vesting.fee.isFee == FEE_STATUS) {
            _fee = vesting.fee;
        }
        for (uint256 idx = 0; idx < vesting.schedules.length; idx++) {
            _schedules.push(vesting.schedules[idx]);
        }
    }

    function redeem(uint256 amount) public {
        (uint256 chainId, address nftAddress, uint256 tokenId) = token();
        require(amount > 0, "ERC6551Account: want amount must be greater than zero");

        require(chainId == block.chainid, "ERC6551Account: invalid chain id");

        (uint256 balance,) = getDataBalanceAndSchedule();

        (uint256 claimableAmount, uint8 batchSize, VestingSchedule[] memory schedules) =
            getClaimableAndSchedule(block.timestamp, amount);

        require(balance > 0, "ERC6551Account: voucher balance must be greater than zero");
        require(
            claimableAmount <= IERC20(tokenAddress).balanceOf(address(this)),
            "ERC6551Account: balance of voucher is insufficient for redeem"
        );

        require(batchSize > 0, "ERC6551Account: not any schedule is available for vesting");
        require(
            claimableAmount <= balance,
            "ERC6551Account: claimable amount must be less than or equal remaining balance of voucher"
        );

        uint256 transferAmount = amount > claimableAmount ? claimableAmount : amount;

        VestingFee memory fee = getDataFee();

        uint256 feeAmount = Math.mulDiv(transferAmount, fee.remainingFee, balance);

        // update voucher data: balance
        _balance = balance - transferAmount;
        IDynamic(_dataRegistry).write(nftAddress, tokenId, keccak256(BALANCE_KEY), abi.encode(_balance));

        // update voucher data: schedule
        for (uint256 idx = 0; idx < schedules.length; idx++) {
            _schedules[idx] = schedules[idx];
        }

        // transfer and update fee
        if (feeAmount > 0 && fee.isFee == FEE_STATUS) {
            require(
                IERC20(fee.feeTokenAddress).transferFrom(msg.sender, address(fee.receiverAddress), feeAmount),
                "ERC6551Account: Transfer fee failed"
            );
            fee.remainingFee -= feeAmount;
            _fee = fee;
        }

        // transfer erc20 token
        require(
            IERC20(tokenAddress).transfer(owner(), transferAmount),
            "ERC6551Account: Transfer ERC20 token claimable amount failed"
        );
    }

    function getClaimableStagedVesting(
        VestingSchedule memory schedule,
        uint256 timestamp,
        uint256 _amount,
        uint8 batchSize,
        uint256 claimableAmount
    ) internal pure returns (VestingSchedule memory, uint256, uint8, uint256) {
        if (timestamp >= schedule.startTimestamp) {
            claimableAmount += schedule.remainingAmount;
            if (_amount < schedule.remainingAmount) {
                schedule.isVested = VESTING_STATUS; // update vesting status
                schedule.remainingAmount -= _amount;
                _amount = 0;
            } else {
                schedule.isVested = VESTED_STATUS;
                _amount -= schedule.remainingAmount;
                schedule.remainingAmount = 0;
            }
            batchSize++;
        }
        return (schedule, claimableAmount, batchSize, _amount);
    }

    function getClaimableLinearVesting(
        VestingSchedule memory schedule,
        uint256 timestamp,
        uint256 _amount,
        uint8 batchSize,
        uint256 claimableAmount
    ) internal pure returns (VestingSchedule memory, uint256, uint8, uint256) {
        if (timestamp >= schedule.endTimestamp) {
            claimableAmount += schedule.remainingAmount;
            if (_amount < schedule.remainingAmount) {
                schedule.isVested = VESTING_STATUS; // update vesting status
                schedule.remainingAmount -= _amount;
                _amount = 0;
            } else {
                schedule.isVested = VESTED_STATUS; // update vesting status
                _amount -= schedule.remainingAmount;
                schedule.remainingAmount = 0;
            }
            batchSize++;
        } else if (timestamp >= schedule.startTimestamp) {
            uint256 linearClaimableAmount = calculateLinearClaimableAmount(timestamp, schedule);
            // claimable amount can not exceed remaining amount
            linearClaimableAmount =
                (schedule.remainingAmount > linearClaimableAmount ? linearClaimableAmount : schedule.remainingAmount);
            claimableAmount += linearClaimableAmount;
            if (_amount < linearClaimableAmount) {
                schedule.remainingAmount -= _amount;
                _amount = 0;
            } else {
                schedule.remainingAmount -= linearClaimableAmount;
                _amount -= linearClaimableAmount;
            }

            // update vesting status
            if (schedule.remainingAmount == 0) {
                schedule.isVested = VESTED_STATUS;
            } else {
                schedule.isVested = VESTING_STATUS;
            }
            batchSize++;
        }
        return (schedule, claimableAmount, batchSize, _amount);
    }

    function getClaimableAndSchedule(uint256 timestamp, uint256 _amount)
        public
        view
        returns (uint256 claimableAmount, uint8 batchSize, VestingSchedule[] memory)
    {
        (, VestingSchedule[] memory schedules) = getDataBalanceAndSchedule();
        uint8 j;
        while (batchSize < REDEEM_BATCH_SIZE && j + 1 <= schedules.length && _amount > 0) {
            if (schedules[j].isVested == VESTED_STATUS) {
                // schedule is already vested, thus ignore
            } else if (schedules[j].vestingType == STAGED_VESTING_TYPE) {
                (schedules[j], claimableAmount, batchSize, _amount) =
                    getClaimableStagedVesting(schedules[j], timestamp, _amount, batchSize, claimableAmount);
            } else if (schedules[j].vestingType == LINEAR_VESTING_TYPE) {
                (schedules[j], claimableAmount, batchSize, _amount) =
                    getClaimableLinearVesting(schedules[j], timestamp, _amount, batchSize, claimableAmount);
            }
            j++;
        }

        return (claimableAmount, batchSize, schedules);
    }

    function calculateLinearClaimableAmount(uint256 timestamp, VestingSchedule memory linearSchedule)
        internal
        pure
        returns (uint256)
    {
        require(linearSchedule.vestingType == LINEAR_VESTING_TYPE, "The vesting type must be LINEAR");
        require(
            timestamp >= linearSchedule.startTimestamp && timestamp < linearSchedule.endTimestamp,
            "Calculating block timestamp must reside in start-end time range of schedule"
        );

        uint256 secondTimeLapse = 1;
        uint256 dailyTimeLapse = 24 * 60 * 60; // in seconds
        uint256 weeklyTimeLapse = 7 * dailyTimeLapse;
        uint256 monthlyTimeLapse = 30 * dailyTimeLapse; // for simplicity we would take 30 days for a month
        uint256 quarterlyTimeLapse = 3 * monthlyTimeLapse;
        uint256 yearlyTimeLapse = 4 * quarterlyTimeLapse;

        uint256 timeLapse;
        if (linearSchedule.linearType == SECOND_LINEAR_VESTING_TYPE) {
            timeLapse = secondTimeLapse;
        } else if (linearSchedule.linearType == DAILY_LINEAR_VESTING_TYPE) {
            timeLapse = dailyTimeLapse;
        } else if (linearSchedule.linearType == WEEKLY_LINEAR_VESTING_TYPE) {
            timeLapse = weeklyTimeLapse;
        } else if (linearSchedule.linearType == MONTHLY_LINEAR_VESTING_TYPE) {
            timeLapse = monthlyTimeLapse;
        } else if (linearSchedule.linearType == QUARTERLY_LINEAR_VESTING_TYPE) {
            timeLapse = quarterlyTimeLapse;
        } else if (linearSchedule.linearType == YEARLY_LINEAR_VESTING_TYPE) {
            timeLapse = yearlyTimeLapse;
        } else {
            revert("unsupported linear vesting type");
        }

        uint256 scheduleTimeRange = linearSchedule.endTimestamp - linearSchedule.startTimestamp;
        uint256 numberLeap = ((timestamp - linearSchedule.startTimestamp) / timeLapse);
        uint256 numberSeconds = numberLeap * timeLapse;
        uint256 claimableAmount = Math.mulDiv(numberSeconds, linearSchedule.amount, scheduleTimeRange);

        return claimableAmount + linearSchedule.remainingAmount - linearSchedule.amount; // actual claimable amount must exclude already vested amount
    }

    function getDataBalanceAndSchedule() public view returns (uint256, VestingSchedule[] memory) {
        return (_balance, _schedules);
    }

    function getDataFee() public view returns (VestingFee memory) {
        return _fee;
    }

    function execute(address, uint256, bytes calldata, uint8) external payable virtual returns (bytes memory) {
        revert("ERC6551Account: does not support this function");
    }

    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC6551Account).interfaceId
            || interfaceId == type(IERC6551Executable).interfaceId;
    }

    function token() public view returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner();
    }

    function state() external view returns (uint256) {
        return _state;
    }

    function schedules(uint256 index) external view returns (VestingSchedule memory) {
        return _schedules[index];
    }

    receive() external payable {}
}
