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
    function decimals() external pure returns (uint8);
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

    function timestampToUTC(uint256 timestamp) public pure returns (string memory utc) {
        if (timestamp  == 0 ) return "";
        DateTime._DateTime memory dt = DateTime.parseTimestamp(timestamp);
        return DateTime.formatDateTime(dt);
    }

    function generateVestingInfoPart(ConstructTokenURIParams memory params) public pure returns (string memory) {
        require(params.schedules.length > 0);

        string memory batchVestingInfo;
        uint256 originalTotalVesting = 0;

        for (uint i = 0; i < params.schedules.length; i++) {
            originalTotalVesting += params.schedules[i].amount;
        }

        for (uint i = 0; i < params.schedules.length; i++) {
            if (params.schedules[i].endTimestamp < params.schedules[i].startTimestamp) {
                params.schedules[i].endTimestamp = params.schedules[i].startTimestamp;
            }

            if (params.schedules[i].startTimestamp == params.schedules[i].endTimestamp) {
                batchVestingInfo = string.concat(
                    batchVestingInfo,
                    "\\n Batch ",
                    (i + 1).toString(),
                    ": ",
                    ((params.schedules[i].amount * 100) / originalTotalVesting).toString(),
                    "% released at ",
                    timestampToUTC(params.schedules[i].startTimestamp)
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
                timestampToUTC(params.schedules[i].startTimestamp)
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
        uint256 timeDiff = schedule.endTimestamp > schedule.startTimestamp ? schedule.endTimestamp - schedule.startTimestamp : 0;
        uint256 duration = timeDiff / 86400;

        if (schedule.vestingType == 1) {
            vestingType = "linear";
        }

        if (schedule.linearType == 2) {
            linearType = "week";
            duration = timeDiff / 86400 / 7;
        } else if (schedule.linearType == 3) {
            linearType = "month";
            duration = timeDiff / 86400 / 30;
        } else if (schedule.linearType == 2) {
            linearType = "quarter";
            duration = timeDiff / 86400 / 120;
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
                // balance: formatTokenBalance(
                //     params.balance,
                //     ILiteERC20(params.voucherToken).decimals()
                // ),
                balance: "0",
                startTime: timestampToUTC(params.schedules[0].startTimestamp),
                endTime: timestampToUTC(
                    params.schedules[params.schedules.length - 1].endTimestamp == 0 ? params.schedules[params.schedules.length - 1].startTimestamp : params.schedules[params.schedules.length - 1].endTimestamp
                ),
                voucherToken: formatAddress(params.voucherToken),
                collectionName: params.collectionName
            });

        return NFTSVG.generateSVG(svgParams);
    } 

    function formatAddress(address _address) public pure returns (string memory) {
        string memory addrStr = addressToString(_address);

        return string(abi.encodePacked(substring(addrStr, 0, 5), "...", substring(addrStr, 38, 42)));
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function formatTokenBalance(uint256 balance, uint8 decimals) public pure returns (string memory) {
        uint256 wholePart = balance / (10 ** decimals);
        uint256 fractionalPart = balance % (10 ** decimals);
        
        string memory wholePartStr = wholePart.toString();
        uint8 fractionDigits = wholePart > 0 ? 2 : 5;

        // Convert the fractional part to string with the required digits
        string memory fractionalPartStr = fractionalPart.toString();
        uint8 fractionalPartLength = uint8(bytes(fractionalPartStr).length);

        // Pad the fractional part with leading zeros if necessary
        uint256 needAddedZero = decimals - fractionalPartLength;
        if (needAddedZero > 4) {
            fractionalPartStr = "0";
        } else {
            while ( needAddedZero > 0)  {
                fractionalPartStr = string(abi.encodePacked("0", fractionalPartStr));
                --needAddedZero;
            }

            fractionalPartStr = substring(fractionalPartStr, 0, fractionDigits);
        }

        // Combine the whole part and fractional part
        return string(abi.encodePacked(addCommas(wholePartStr), ".", fractionalPartStr));
    }
   
    // Helper function to add commas to a string representation of a number
    function addCommas(string memory numStr) internal pure returns (string memory) {
        bytes memory numBytes = bytes(numStr);
        uint256 length = numBytes.length;
        if (length <= 3) {
            return numStr; // No commas needed
        }

        uint256 commas = (length - 1) / 3;
        bytes memory result = new bytes(length + commas);
        uint256 j = result.length;
        uint256 k = length;

        for (uint256 i = 0; i < length; i++) {
            --j;
            --k;
            if (i > 0 && i % 3 == 0) {
                result[j] = ",";
                --j;
            }
            result[j] = numBytes[k];

        }

        return string(result);
    }

}
