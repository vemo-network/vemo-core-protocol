// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/interfaces/darenft/IFactory.sol";
import "forge-std/Test.sol";

contract Factory is Test {
    function createCollection(
        string calldata name,
        string calldata symbol,
        IFactory.CollectionSettings calldata settings,
        IFactory.CollectionKind kind
    ) external pure returns (address collection) {
        return vm.addr(uint256(keccak256(abi.encodePacked(name, symbol))));
    }
}
