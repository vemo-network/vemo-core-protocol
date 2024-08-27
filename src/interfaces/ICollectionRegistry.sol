// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICollectionRegistry {
    function parameters()
        external
        view
        returns (
            string calldata name,
            string calldata symbol,
            address owner,
            address walletFactory,
            address descriptor, 
            address term,
            address issuer
        );
}
