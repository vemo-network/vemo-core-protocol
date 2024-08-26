// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../BitMath.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

/// @title NFTDelegationSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTDelegationSVG {
    struct SVGParams {
        string nftId;
        string tba;
        string collectionName;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    generate(params)
                )
            );
    }

    function generate(SVGParams memory params) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<svg width="284" height="120" viewBox="0 0 284 120" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="284" height="120" rx="12" fill="#0D131C"/><rect width="284" height="96" fill="url(#pattern0_9657_28076)"/><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" font-weight="600" letter-spacing="0em"><tspan x="86" y="40.1">',
                    params.collectionName,
                    '</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="12" font-weight="500" letter-spacing="0em"><tspan x="86" y="60.1">Smart Wallet Address</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="16" font-weight="500" letter-spacing="0em"><tspan x="226" y="59.6">#',
                    params.nftId,
                    '</tspan></text><text fill="white" fill-opacity="0.6" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="12" letter-spacing="0.05em"><tspan x="110" y="90.2">',
                    params.tba,
                    '</tspan></text><text fill="#3CCBCD" xml:space="preserve" style="white-space: pre" font-family="Montserrat Thin" font-size="10" font-weight="500" letter-spacing="0em"><tspan x="8.07324" y="110.585">DELEGATE</tspan></text><path d="M0 25H62C66.4183 25 70 28.5817 70 33V87C70 91.4183 66.4183 95 62 95H0V25Z" fill="white" fill-opacity="0.05"/><path d="M38.4643 68.9234L35.2101 74.5398C34.8455 75.1691 33.9107 75.1489 33.575 74.5043L27.4526 62.7488C27.244 62.3483 27.6945 61.927 28.0947 62.1483L38.1136 67.687C38.5599 67.9337 38.7169 68.4874 38.4643 68.9234Z" fill="white"/><path d="M44.5423 45.8541L25.3066 55.8328C24.6169 56.1906 23.761 55.9243 23.4099 55.2427L19.1504 46.9723C18.6844 46.0674 19.3575 45 20.3942 45L44.3246 45C44.8083 45 44.9695 45.6325 44.5423 45.8541Z" fill="white"/><path d="M50.8291 46.9347L40.0676 65.7639C39.8164 66.2035 39.2469 66.359 38.7989 66.1105L26.2408 59.1439C25.6153 58.7969 25.6139 57.9166 26.2382 57.5676L47.9051 45.4577C48.4416 45.1578 49.049 45 49.6672 45C50.6833 45 51.3246 46.0678 50.8291 46.9347Z" fill="#0047FF"/><defs><pattern id="pattern0_9657_28076" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#image0_9657_28076" transform="scale(0.00352113 0.0104167)"/></pattern></defs></svg>'
                )
            );
    }
}
