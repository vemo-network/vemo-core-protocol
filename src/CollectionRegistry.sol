// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/ICollectionRegistry.sol";
import "./helpers/VemoDelegationCollection.sol";
import "./helpers/Errors.sol";

contract CollectionRegistry is ICollectionRegistry {
    struct DelegateCollectionParameters {
        string  name;
        string  symbol;
        address owner;
        address walletFactory;
        address descriptor; 
        address term;
        address issuer;
    }

    DelegateCollectionParameters public parameters;

    function createDelegateCollection(
        string memory name,
        string memory symbol,
        address descriptor, 
        address term,
        address issuer,
        address walletFactory
    ) public returns (address collection) {
        if (descriptor == address(0)) revert InvalidDescriptor();
        parameters = DelegateCollectionParameters({
            name: name,
            symbol: symbol,
            owner: walletFactory,
            walletFactory: walletFactory,
            descriptor: descriptor , 
            term: term,
            issuer: issuer
        });

        collection = address(new VemoDelegationCollection{salt: keccak256(abi.encode(term, issuer))}());

        delete parameters;

        return collection;
    }


}
