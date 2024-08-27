// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegationCollection {
    function term() external view returns (address);
    function issuer() external view returns (address);
    function safeMint(uint256 tokenId, address to) external returns (uint256);
}
