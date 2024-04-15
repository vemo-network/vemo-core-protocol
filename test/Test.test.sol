// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract DemoTest is Test {

    function test() public view {
        uint256 x = 7;
        uint256 y = 1;
        uint256 z = 10;

        uint256 r = Math.mulDiv(x, y, z);
        console.log(r);
    }
}
