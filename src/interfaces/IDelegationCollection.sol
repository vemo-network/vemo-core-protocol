// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegationCollection {
    function term() external view returns (address);
    function issuer() external view returns (address);
    function tba(uint256) external view returns (address);

    // actions
    function burn(uint256 tokenId) external;
    function delegate(uint256 tokenId, address receiver) external;
    function revoke(uint256 tokenId) external;
}
