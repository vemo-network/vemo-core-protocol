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

    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function generateDescriptionPart(
        ConstructTokenURIParams memory params
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT, referred to as a smart voucher, contains ",
                    params.collectionName,
                    " tokens. The holder has the ability to claim these tokens following the on-chain vesting schedule, and can also transfer or sell it on the secondary market. Read more on https://vemo.network/ \\n\\n\n- Token Address: ",
                    addressToString(params.voucherToken),
                    generateVestingInfoPart(params),
                    unicode"⚠️ DISCLAIMER: warning icon: IMPORTANT: It is essential to exercise due diligence when assessing this voucher. Please ensure the token address in the voucher matches the expected token, as token symbols may be imitated"
                )
            );
    }

    function convertTimestampToUTC(uint256 timestamp) private pure returns (string memory utc) {
        return  string.concat(
            uint256(DateTime.getMonth(timestamp)).toString(),
            "/",
            uint256(DateTime.getDay(timestamp)).toString(),
            "/",
            uint256(DateTime.getYear(timestamp)).toString(),
            " ",
            uint256(DateTime.getHour(timestamp)).toString(),
            ":",
            uint256(DateTime.getMinute(timestamp)).toString(),
            ":",
            uint256(DateTime.getSecond(timestamp)).toString(),
            " UTC"
        );
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
    function generateVestingInfoPart(ConstructTokenURIParams memory params) private pure returns (string memory) {
        require(params.schedules.length > 0);
        string memory vestingType = "staged";
        string memory linearType = "daily";

        if (params.schedules[0].vestingType == 1) {
            vestingType = "linear";
        }

        if (params.schedules[0].linearType == 2) {
            linearType = "weekly";
        } else if (params.schedules[0].linearType == 3) {
            linearType = "monthly";
        } else if (params.schedules[0].linearType == 2) {
            linearType = "quarterly";
        }

        return string.concat(
            " \\n\n- Vesting schedule: ",
            linearType,
            " ",
            vestingType,
            " release in ",
            ((params.schedules[0].endTimestamp - params.schedules[0].startTimestamp) / (24*60*60*7)).toString(),
            " weeks, starting at ",
            convertTimestampToUTC(params.schedules[0].startTimestamp),
            "\\n\\n\n"
        );
    }

    function generateName(ConstructTokenURIParams memory params)
        private
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

    function scale(
        uint256 n,
        uint256 inMn,
        uint256 inMx,
        uint256 outMn,
        uint256 outMx
    ) private pure returns (string memory) {
        return (n - (inMn)*(outMx - (outMn))/(inMx - (inMn)) + (outMn)).toHexString(20);
    }

    function getCircleCoord(
        uint256 tokenAddress,
        uint256 offset,
        uint256 tokenId
    ) internal pure returns (uint256) {
        return (sliceTokenHex(tokenAddress, offset) * tokenId) % 255;
    }

    function sliceTokenHex(uint256 token, uint256 offset) internal pure returns (uint256) {
        return uint256(uint8(token >> offset));
    }
}
