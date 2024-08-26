// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import './INFTDelegationDescriptor.sol';
import '../HexStrings.sol';
import './NFTDelegationSVG.sol';
import '../DateTime.sol';

interface ILiteERC20 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
}
contract NFTDelegationDescriptor is INFTDelegationDescriptor, UUPSUpgradeable {
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
                    "This NFT, referred to as a smart wallet delegation role. The holder has the ability to vote on behalf of the TBA owner, and can also transfer or sell the NFT itself on the secondary market. Read more on https://vemo.network/ \\n\\n\\n ",
                    unicode"⚠️ DISCLAIMER: It is essential to exercise due diligence when assessing this smart wallet. Please ensure the token address in the smart wallet matches the expected token, as token symbols may be imitated"
                )
            );
    }

    function timestampToUTC(uint256 timestamp) public pure returns (string memory utc) {
        if (timestamp  == 0 ) return "";
        DateTime._DateTime memory dt = DateTime.parseTimestamp(timestamp);
        return DateTime.formatDateTime(dt);
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
         NFTDelegationSVG.SVGParams memory svgParams =
            NFTDelegationSVG.SVGParams({
                nftId: params.nftId.toString(),
                tba: formatAddress(params.tba),
                collectionName: params.collectionName
            });

        return NFTDelegationSVG.generateSVG(svgParams);
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

}
