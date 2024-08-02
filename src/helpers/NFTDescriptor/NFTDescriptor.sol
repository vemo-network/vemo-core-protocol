// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import './INFTDescriptor.sol';
import './HexStrings.sol';
import './NFTSVG.sol';
import './DateTime.sol';

interface ILiteERC20 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
}
contract NFTDescriptor is INFTDescriptor, UUPSUpgradeable {
    using Strings for uint256;

    address public _owner;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == _owner || msg.sender == address(this), "only owner");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        (newImplementation);
        _onlyOwner();
    }

    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function initialize(
        address owner
    ) public virtual initializer {
        _owner = owner;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) public pure  override returns (string memory) {
        string memory name = generateName(params);
        string memory descriptionPart = generateDescriptionPart(params);
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPart,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateDescriptionPart(
        ConstructTokenURIParams memory params
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT, referred to as a smart voucher, contains ",
                    ILiteERC20(params.voucherToken).symbol(),
                    " tokens. The holder has the ability to claim these tokens following the on-chain vesting schedule, and can also transfer or sell it on the secondary market. Read more on https://vemo.network/ \\n\\n\\n- Token Address: ",
                    addressToString(params.voucherToken),
                    generateVestingInfoPart(params),
                    unicode"⚠️ DISCLAIMER: It is essential to exercise due diligence when assessing this voucher. Please ensure the token address in the voucher matches the expected token, as token symbols may be imitated"
                )
            );
    }

    function convertTimestampToUTC(uint256 timestamp) public pure returns (string memory utc) {
        DateTime._DateTime memory dt = DateTime.parseTimestamp(timestamp);
        return DateTime.formatDateTime(dt);
    }

    /**
     * 
     * struct VestingSchedule {
        uint256 amount;
        uint8 vestingType; // linear: 1 | staged: 2
        uint8 linearType; // day: 1 | week: 2 | month: 3 | quarter: 4
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint8 isVested; // unvested: 0 | vested : 1 | vesting : 2
        uint256 remainingAmount;
        }
     */
    function generateVestingInfoPart(ConstructTokenURIParams memory params) public pure returns (string memory) {
        require(params.schedules.length > 0);

        string memory batchVestingInfo;
        uint256 originalTotalVesting = 0;

        for (uint i = 0; i < params.schedules.length; i++) {
            originalTotalVesting += params.schedules[i].amount;
        }

        for (uint i = 0; i < params.schedules.length; i++) {
            if (params.schedules[i].startTimestamp == params.schedules[i].endTimestamp) {
                batchVestingInfo = string.concat(
                    batchVestingInfo,
                    "\\n Batch ",
                    (i + 1).toString(),
                    ": ",
                    ((params.schedules[i].amount * 100) / originalTotalVesting).toString(),
                    "% released at ",
                    convertTimestampToUTC(params.schedules[i].startTimestamp)
                );
                continue;
            }

            batchVestingInfo = string.concat(
                batchVestingInfo,
                "\\n Batch ",
                (i + 1).toString(),
                ": ",
                ((params.schedules[i].amount * 100) / originalTotalVesting).toString(),
                "% ",
                genSingleVestingText(params.schedules[i]),
                " starting at ",
                convertTimestampToUTC(params.schedules[i].startTimestamp)
            );
        }
        return string.concat(
            " \\n\\n- Vesting schedule: ",
            batchVestingInfo,
            "\\n\\n\\n"
        );
    }

    function genSingleVestingText(VestingSchedule memory schedule) pure private returns(string memory) {
        string memory vestingType = "staged";
        string memory linearType = "day";
        uint256 duration = (schedule.endTimestamp - schedule.startTimestamp) / 86400;

        if (schedule.vestingType == 1) {
            vestingType = "linear";
        }

        if (schedule.linearType == 2) {
            linearType = "week";
            duration = (schedule.endTimestamp - schedule.startTimestamp) / 86400 / 7;
        } else if (schedule.linearType == 3) {
            linearType = "month";
            duration = (schedule.endTimestamp - schedule.startTimestamp) / 86400 / 30;
        } else if (schedule.linearType == 2) {
            linearType = "quarter";
            duration = (schedule.endTimestamp - schedule.startTimestamp) / 86400 / 120;
        }
        
        return string.concat(
            keccak256(abi.encodePacked(linearType)) == keccak256(abi.encodePacked("day")) ? "daily" : string.concat(linearType, "ly"),
            " ",
            vestingType,
            " release in ",
            duration.toString(),
            " ",
            duration > 1 ? string.concat(linearType, "s") : linearType
        );
    }

    function generateName(ConstructTokenURIParams memory params)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    params.collectionName,
                    " #",
                    params.nftId.toString()
                )
            );
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }

    function generateSVGImage(ConstructTokenURIParams memory params) internal pure returns (string memory svg) {
        NFTSVG.SVGParams memory svgParams =
            NFTSVG.SVGParams({
                nftId: params.nftId.toString(),
                balance: params.balance.toString(),
                startTime: params.schedules[0].startTimestamp.toString(),
                endTime: params.schedules[params.schedules.length - 1].endTimestamp.toString(),
                voucherToken: addressToString(params.voucherToken),
                collectionName: params.collectionName
            });

        return NFTSVG.generateSVG(svgParams);
    }

}
