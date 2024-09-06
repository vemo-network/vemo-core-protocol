// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import "./IterableMap.sol";

contract IterableMapTest is Test {
    Store store;
    using IterableMap for Store;

    function setUp() public {
        store.set(0x0000000000000000000000000000000000000001, 10);
        store.set(0x0000000000000000000000000000000000000002, 20);
        store.set(0x0000000000000000000000000000000000000003, 30);
        store.set(0x0000000000000000000000000000000000000004, 40);
        store.set(0x0000000000000000000000000000000000000005, 50);
    }

    function testEntries() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        assertEq(keys.length, 5, "keys length");
        assertEq(values.length, 5, "values length");
    }

    function testEntriesLimit() public {
        (address[] memory keys, uint96[] memory values) = store.entries(0x0000000000000000000000000000000000000005, 3);
        assertEq(keys[0], 0x0000000000000000000000000000000000000004, "start key");
        assertEq(keys.length, 3, "keys length");
        assertEq(values.length, 3, "values length");
    }

    function testEntriesHalfLimit() public {
        (address[] memory keys, uint96[] memory values) = store.entries(0x0000000000000000000000000000000000000003, 3);
        assertEq(keys[0], 0x0000000000000000000000000000000000000002, "start key");
        assertEq(keys.length, 2, "keys length");
        assertEq(values.length, 2, "values length");
    }

    function testSet() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.set(0x0000000000000000000000000000000000000002, 13);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length, keysA.length, "keys length");
        assertEq(values.length, valuesA.length, "values length");
        assertEq(store.get(0x0000000000000000000000000000000000000002), 13, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testSetFirst() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.set(keys[0], 13);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length, keysA.length, "keys length");
        assertEq(values.length, valuesA.length, "values length");
        assertEq(store.get(keys[0]), 13, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testSetLast() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.set(keys[keys.length-1], 13);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length, keysA.length, "keys length");
        assertEq(values.length, valuesA.length, "values length");
        assertEq(store.get(keys[keys.length-1]), 13, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testInsert() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.set(0x0000000000000000000000000000000000000006, 60);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length+1, keysA.length, "keys length");
        assertEq(values.length+1, valuesA.length, "values length");
        assertEq(store.get(0x0000000000000000000000000000000000000006), 60, "store value");
        assertEq(keysA[0], 0x0000000000000000000000000000000000000006, "key");
        assertEq(valuesA[0], 60, "value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDelete() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(0x0000000000000000000000000000000000000013);
        store.remove(0x0000000000000000000000000000000000000003);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-1, keysA.length, "keys length");
        assertEq(values.length-1, valuesA.length, "values length");
        assertEq(store.get(0x0000000000000000000000000000000000000003), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDelete2() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(0x0000000000000000000000000000000000000003);
        store.remove(0x0000000000000000000000000000000000000002);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-2, keysA.length, "keys length");
        assertEq(values.length-2, valuesA.length, "values length");
        assertEq(store.get(0x0000000000000000000000000000000000000003), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDeleteFirst() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[0]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-1, keysA.length, "keys length");
        assertEq(values.length-1, valuesA.length, "values length");
        assertEq(store.get(keys[0]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDeleteFirst2() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[0]);
        store.remove(keys[1]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-2, keysA.length, "keys length");
        assertEq(values.length-2, valuesA.length, "values length");
        assertEq(store.get(keys[0]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDeleteLast() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[keys.length-1]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-1, keysA.length, "keys length");
        assertEq(values.length-1, valuesA.length, "values length");
        assertEq(store.get(keys[keys.length-1]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDeleteLast2() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[keys.length-1]);
        store.remove(keys[keys.length-2]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-2, keysA.length, "keys length");
        assertEq(values.length-2, valuesA.length, "values length");
        assertEq(store.get(keys[keys.length-1]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDeleteFirstLast() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[keys.length-1]);
        store.remove(keys[0]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-2, keysA.length, "keys length");
        assertEq(values.length-2, valuesA.length, "values length");
        assertEq(store.get(keys[keys.length-1]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testDelete3() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        store.remove(keys[keys.length-1]);
        store.remove(keys[0]);
        store.remove(keys[1]);
        (address[] memory keysA, uint96[] memory valuesA) = store.entries();
        assertEq(keys.length-3, keysA.length, "keys length");
        assertEq(values.length-3, valuesA.length, "values length");
        assertEq(store.get(keys[keys.length-1]), 0, "store value");
        store.compact();
        (address[] memory keysB, uint96[] memory valuesB) = store.entries();
        assertEq(keysB.length, keysA.length, "keys length");
        assertEq(valuesB.length, valuesA.length, "values length");
        for (uint i = 0; i < keysA.length; ++i) {
            assertEq(keysA[i], keysB[i], "keys");
            assertEq(valuesA[i], valuesB[i], "values");
        }
    }

    function testCompact() public {
        (address[] memory keys, ) = store.entries();
        store.remove(0x0000000000000000000000000000000000000001);
        store.remove(0x0000000000000000000000000000000000000004);
        store.compact(0x0000000000000000000000000000000000000005, 3);
        (address[] memory keysA, ) = store.entries();
        assertEq(keysA.length, keys.length-2, "lengthA");
        store.compact();
        (address[] memory keysB, ) = store.entries();
        assertEq(keysB.length, keys.length-2, "lengthB");
    }
}