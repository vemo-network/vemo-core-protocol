// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../BitMath.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

/// @title NFTAccountSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTAccountSVG {
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
                    '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="500" height="500" rx="24" fill="#394E86"/><g style="mix-blend-mode:screen"><rect width="500" height="421" fill="url(#pattern0_9707_52156)"/></g><path d="M0 170H136C149.255 170 160 180.745 160 194V306C160 319.255 149.255 330 136 330H0V170Z" fill="white" fill-opacity="0.1"/><text fill="white" fill-opacity="0.5" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" font-weight="500" letter-spacing="0.6em"><tspan x="56" y="428">POWERED BY VEMO</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="28" font-weight="500" letter-spacing="0em"><tspan x="196" y="269.8">NFT Account</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="48" font-weight="600" letter-spacing="0em"><tspan x="196" y="212.3">Vemo</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="32" font-weight="500" letter-spacing="0em"><tspan x="56" y="98.2">#',
                    params.nftId,
                    '</tspan></text><text fill="white" fill-opacity="0.6" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="28" letter-spacing="0.05em"><tspan x="196" y="317.8">',
                    params.tba,
                    '</tspan></text><path d="M88.6607 272.606L80.5253 286.834C79.6137 288.429 77.2768 288.377 76.4376 286.744L61.1314 256.964C60.6099 255.949 61.7362 254.882 62.7369 255.442L87.7839 269.474C88.8998 270.099 89.2923 271.501 88.6607 272.606Z" fill="white"/><path d="M103.856 214.164L55.7665 239.443C54.0422 240.349 51.9024 239.675 51.0248 237.948L40.3761 216.997C39.211 214.704 40.8938 212 43.4855 212L103.312 212C104.521 212 104.924 213.602 103.856 214.164Z" fill="white"/><path d="M119.573 216.901L92.669 264.602C92.0409 265.716 90.6172 266.11 89.4971 265.48L58.1021 247.831C56.5383 246.952 56.5347 244.722 58.0956 243.838L112.263 213.159C113.604 212.4 115.123 212 116.668 212C119.208 212 120.812 214.705 119.573 216.901Z" fill="#0047FF"/><defs><pattern id="pattern0_9707_52156" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#image0_9707_52156" transform="scale(0.002 0.0023753)"/></pattern></defs></svg>'
                )
            );
    }
}
