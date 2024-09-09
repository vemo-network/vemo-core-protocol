// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICollectionDeployer {
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
    
    function createDelegateCollection(
        string memory name,
        string memory symbol,
        address descriptor, 
        address term,
        address issuer,
        address walletFactory
    ) external returns (address collection);

    function createVemoCollection(
        string memory name,
        string memory symbol,
        uint256 salt,
        address walletFactory,
        address descriptor
    ) external returns (address nftAddress);
}
