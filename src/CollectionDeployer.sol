// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/ICollectionDeployer.sol";
import "./helpers/VemoDelegationCollection.sol";
import "./helpers/VemoWalletCollection.sol";
import "./helpers/Errors.sol";

contract CollectionDeployer is ICollectionDeployer, Ownable {
    string public name;
    string public symbol;
    address transient public collectionOwner;
    address transient public walletFactory;
    address transient public descriptor; 
    address transient public term;
    address transient public issuer;

    constructor(address owner) Ownable(owner) {}

    function createDelegateCollection(
        string memory _name,
        string memory _symbol,
        address _descriptor, 
        address _term,
        address _issuer,
        address _walletFactory
    ) public onlyOwner returns (address collection)  {
        if (_descriptor == address(0)) revert InvalidDescriptor();
        
        name = _name;
        symbol = _symbol;
        descriptor = _descriptor;
        term = _term;
        issuer = _issuer;
        walletFactory = _walletFactory;
        collectionOwner = _walletFactory;

        collection = address(new VemoDelegationCollection{salt: keccak256(abi.encode(term, issuer))}());

        delete name;
        delete symbol;

        return collection;
    }

    function createVemoCollection(
        string memory _name,
        string memory _symbol,
        uint256 salt,
        address _walletFactory,
        address _descriptor
    ) public onlyOwner returns (address nftAddress) {
        name = _name;
        symbol = _symbol;
        descriptor = _descriptor;
        walletFactory = _walletFactory;
        collectionOwner = _walletFactory;

        nftAddress = address(new VemoWalletCollection{salt: bytes32(salt)}());

        delete name;
        delete symbol;

        return nftAddress;
    }
}
