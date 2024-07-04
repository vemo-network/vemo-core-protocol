// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/ICollectionRegistry.sol";

contract CollectionRegistry is ICollectionRegistry {
    function getCreationCode(
        address implementation,
        uint256 collectionIndex,
        string calldata name,
        string calldata symbol
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73", // ERC-1167 constructor + header
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3", // ERC-1167 footer
            abi.encode(uint256(collectionIndex), name, symbol)
        );
    }

    function createCollection(
        address implementation,
        uint256 collectionIndex,
        string calldata name,
        string calldata symbol,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = getCreationCode(implementation, collectionIndex, name, symbol);

        address _collection = Create2.computeAddress(bytes32(collectionIndex), keccak256(code));

        if (_collection.code.length != 0) return _collection;

        emit CollectionCreated(_collection, implementation, collectionIndex, name, symbol);

        _collection = Create2.deploy(0, bytes32(collectionIndex), code);

        if (initData.length != 0) {
            (bool success,) = _collection.call(initData);
            if (!success) revert CollectionCreationFailed();
        }

        return _collection;
    }

    function collection(address implementation, uint256 collectionIndex, string calldata name, string calldata symbol)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(getCreationCode(implementation, collectionIndex, name, symbol));

        return Create2.computeAddress(bytes32(collectionIndex), bytecodeHash);
    }
}
