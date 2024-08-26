// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '../BitMath.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    struct SVGParams {
        string nftId;
        string balance;
        string startTime;
        string endTime;
        string voucherToken;
        string collectionName;
    }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    generateFirstPart(params),
                    generateSecondPart(params)
                )
            );
    }

    function generateFirstPart(SVGParams memory params) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="500" height="500" rx="24" fill="#393492"/><g style="mix-blend-mode:screen"><mask id="mask0_9157_14436" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="500" height="421"><rect width="500" height="421" rx="24" fill="#D9D9D9"/></mask><g mask="url(#mask0_9157_14436)"><rect x="-239" width="739" height="409" fill="url(#pattern0_9157_14436)"/></g></g><text fill="white" fill-opacity="0.6" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" letter-spacing="0.05em"><tspan x="60" y="398">Start Time </tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" letter-spacing="0em"><tspan x="184" y="398">',
                    params.startTime,
                    '</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="28" letter-spacing="0em"><tspan x="60" y="218.8">',
                    params.voucherToken,
                    '</tspan></text><text fill="white" fill-opacity="0.6" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" letter-spacing="0.05em"><tspan x="60" y="434">End time: </tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="20" letter-spacing="0em"><tspan x="184" y="434">',
                    params.endTime
                )
            );
    }

    function generateSecondPart(SVGParams memory params) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="42" font-weight="500" letter-spacing="0em"><tspan x="60" y="178.2">',
                    params.collectionName,
                    '</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="32" font-weight="500" letter-spacing="0em"><tspan x="60" y="75.2">',
                    "# ", params.nftId,
                    '</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Urbanist" font-size="60" font-weight="600" letter-spacing="0em"><tspan x="60" y="312">',
                    params.balance,
                    '</tspan></text><defs><pattern id="pattern0_9157_14436" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#image0_9157_14436" transform="matrix(0.000416755 0 0 0.000753012 -0.000314349 0)"/></pattern></defs></svg>'
                )
            );
    }
}
