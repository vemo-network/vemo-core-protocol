// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICollectionDeployer {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function collectionOwner() external view returns(address);
    function walletFactory() external view returns(address);
    function descriptor() external view returns(address);
    function term() external view returns(address);
    function issuer() external view returns(address);

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
