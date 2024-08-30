// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MockReverter.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract MockVePendle is MockReverter {
    function claim() external returns (uint256) {
        msg.sender.call{value: 1 ether}("");
        return 12345;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x12345678;
    }

}
