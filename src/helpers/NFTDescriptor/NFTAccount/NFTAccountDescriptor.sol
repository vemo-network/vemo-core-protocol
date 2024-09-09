// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import './INFTAccountDescriptor.sol';
import '../HexStrings.sol';
import './NFTAccountSVG.sol';
import '../DateTime.sol';

interface ILiteERC20 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
}
contract NFTAccountDescriptor is INFTAccountDescriptor, UUPSUpgradeable {
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
                    "This NFT signifies the ownership of an account containing crypto assets or off-chain points, known as a Vemo NFT Account following the ERC-6551 standard. Only NFT holder has complete control over the assets in the account. Additionally, they can transfer the account to others by transferring or selling NFT on the secondary market.\\n\\n Vemo Account address linked to this NFT: ",
                    addressToString(params.tba),
                    "\\n\\nFor more details, please visit https://vemo.network/\\n\\n",
                    unicode"⚠️ DISCLAIMER: It is highly recommended to verify the assets in the NFT Account on Vemo Network website before making any decisions."
                )
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
         NFTAccountSVG.SVGParams memory svgParams =
            NFTAccountSVG.SVGParams({
                nftId: params.nftId.toString(),
                tba: formatAddress(params.tba),
                collectionName: params.collectionName
            });

        return NFTAccountSVG.generateSVG(svgParams);
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
