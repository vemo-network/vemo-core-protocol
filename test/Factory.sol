// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/interfaces/IFactory.sol";

contract Factory {
    function createCollection(
        string calldata name,
        string calldata symbol,
        IFactory.CollectionSettings calldata settings,
        IFactory.CollectionKind kind
    ) external returns (address collection) {}
}
