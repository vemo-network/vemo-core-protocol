// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20("USDC", "USDC") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
