// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/ICollectionDeployer.sol";
import "./helpers/VemoDelegationCollection.sol";
import "./helpers/VemoWalletCollection.sol";
import "./helpers/Errors.sol";

contract CollectionDeployer is ICollectionDeployer, Ownable {
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

    constructor(address owner) Ownable(owner) {}

    function createDelegateCollection(
        string memory name,
        string memory symbol,
        address descriptor, 
        address term,
        address issuer,
        address walletFactory
    ) public onlyOwner returns (address collection)  {
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


     function createVemoCollection(
        string memory name,
        string memory symbol,
        string memory dappURI,
        uint256 salt
    ) public onlyOwner returns (address nftAddress) {
        bytes memory bytecode = abi.encodePacked(
            type(VemoWalletCollection).creationCode,
            abi.encode(
                name,
                symbol,
                owner()
            )
        );
        bytes32 saltHash = keccak256(abi.encodePacked(salt));

        assembly {
            nftAddress := create2(0, add(bytecode, 0x20), mload(bytecode), saltHash)
            if iszero(extcodesize(nftAddress)) {
                revert(0, 0)
            }
        }

        return nftAddress;
    }
}
