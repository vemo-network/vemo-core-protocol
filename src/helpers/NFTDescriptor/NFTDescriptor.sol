// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import './INFTDescriptor.sol';
import './HexStrings.sol';
import './NFTSVG.sol';

contract NFTDescriptor is INFTDescriptor, UUPSUpgradeable {
    using HexStrings for uint256;

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
                    params.voucherToken,
                    " \\n\n- Vesting schedule: 100% monthly linear release in 6 months starting at 16/04/2024 07:00:00 UTC \\n\\n\n",
                    unicode"⚠️ DISCLAIMER: warning icon: IMPORTANT: It is essential to exercise due diligence when assessing this voucher. Please ensure the token address in the voucher matches the expected token, as token symbols may be imitated"
                )
            );
    }

    // function generateVestingPart() {

    // }

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
                    params.voucherToken
                )
            );
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return (uint256(uint160(addr))).toHexString(20);
    }

    function generateSVGImage(ConstructTokenURIParams memory params) internal pure returns (string memory svg) {
        NFTSVG.SVGParams memory svgParams =
            NFTSVG.SVGParams({
                nftId: params.nftId,
                balance: params.balance,
                startTime: params.schedules[0].startTimestamp,
                endTime: params.schedules[params.schedules.length - 1].endTimestamp,
                voucherToken: params.voucherToken,
                nftAddress: params.nftAddress,
                collectionName: params.collectionName,
                color0: tokenToColorHex(uint256(uint160(params.voucherToken)), 136),
                color1: tokenToColorHex(uint256(uint160(params.nftAddress)), 136),
                color2: tokenToColorHex(uint256(uint160(params.voucherToken)), 0),
                color3: tokenToColorHex(uint256(uint160(params.nftAddress)), 0),
                x1: scale(getCircleCoord(uint256(uint160(params.voucherToken)), 16, params.nftId), 0, 255, 16, 274),
                y1: scale(getCircleCoord(uint256(uint160(params.nftAddress)), 16, params.nftId), 0, 255, 100, 484),
                x2: scale(getCircleCoord(uint256(uint160(params.voucherToken)), 32, params.nftId), 0, 255, 16, 274),
                y2: scale(getCircleCoord(uint256(uint160(params.nftAddress)), 32, params.nftId), 0, 255, 100, 484),
                x3: scale(getCircleCoord(uint256(uint160(params.voucherToken)), 48, params.nftId), 0, 255, 16, 274),
                y3: scale(getCircleCoord(uint256(uint160(params.nftAddress)), 48, params.nftId), 0, 255, 100, 484)
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

    function tokenToColorHex(uint256 token, uint256 offset) internal pure returns (string memory str) {
        return string((token >> offset).toHexStringNoPrefix(3));
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
