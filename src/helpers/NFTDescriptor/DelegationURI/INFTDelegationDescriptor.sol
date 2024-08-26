// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


interface INFTDelegationDescriptor {
    struct ConstructTokenURIParams {
        uint256 nftId;
        address nftAddress;
        address tba;
        string collectionName;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) external pure returns (string memory);
}
