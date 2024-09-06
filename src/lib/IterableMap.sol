// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.21;

import "@solidity-bytes-utils/BytesLib.sol";

struct Value {
    address next;
    uint96 value;
}

struct Store {
    mapping(address => Value) values;
}

/// iterable mapping(address => uint96)
/// + get/set: 1 storage access
/// + insert new: 2 storage write
/// + entries: designed for non-contract call
/// + compact: trussless function (for anyone) to remove zero-value items
library IterableMap {
    using IterableMap for Store;

    address constant NOA = address(0);

    function first(Store storage store) view internal returns (address) {
        return store.values[NOA].next;
    }

    function setFirst(Store storage store, address key) internal {
        store.values[NOA].next = key;
    }

    function get(Store storage store, address key) view internal returns (uint96) {
        return store.values[key].value;
    }

    function set(Store storage store, address key, uint96 value) internal {
        require(key != NOA, "Zero Address");
        Value memory old = store.values[key];
        if (old.next == NOA && old.value == 0) {
            if (value == 0) {
                return; // remove a non-existing key
            }
            store.values[key].next = store.first();
            store.setFirst(key);
        }
        store.values[key].value = value;
    }

    function remove(Store storage store, address key) internal {
        return store.set(key, 0);
    }

    function entries(Store storage store) view internal returns (address[] memory keys, uint96[] memory values) {
        return store.entries(NOA, type(uint256).max);
    }

    function compact(Store storage store) internal {
        store.compact(NOA, type(uint256).max);
    }

    /// loop through the single linked list and skip any empty value
    function entries(Store storage store, address last, uint limit) view internal returns (address[] memory keys, uint96[] memory values) {
        bytes memory buffer;
        address key = last;
        for (uint i = 0; i < limit; ++i) {
            key = store.values[key].next;
            if (key == NOA) {
                break;
            }
            Value memory old = store.values[key];
            if (old.value > 0) {
                buffer = bytes.concat(buffer, abi.encodePacked(key, old.value));
            }
        }
        if (buffer.length >= 32) {
            keys = new address[](buffer.length/32);
            values = new uint96[](buffer.length/32);
            for (uint i = 0; i < keys.length; ++i) {
                keys[i] = BytesLib.toAddress(buffer, i*32);
                values[i] = BytesLib.toUint96(buffer, i*32 + 20);
            }
        }
    }

    /// remove any empty value from the list
    /// this function is trustless, and can be called by anyone
    function compact(Store storage store, address last, uint limit) internal {
        address key = last;
        for (uint i = 0; i < limit; ++i) {
            key = store.values[key].next;
            if (key == NOA) {
                break;
            }
            Value memory old = store.values[key];
            if (old.value == 0) {
                store.values[last].next = old.next;
                delete store.values[key];
                key = last;
            } else {
                last = key;
            }
        }
    }
}
