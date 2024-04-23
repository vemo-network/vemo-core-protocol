// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20("USDT", "USDT") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
