// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import "../../src/lib/IterableMap.sol";

contract IterableMapTest is Test {
    Store store;
    using IterableMap for Store;

    function setUp() public {
        uint gas = gasleft();
        store.set(0x0000000000000000000000000000000000000001, 10);
        assertLe(gas - gasleft(), 50000);
        gas = gasleft();
        store.set(0x0000000000000000000000000000000000000002, 20);
        assertLe(gas - gasleft(), 25000);
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

    function testGet() public {
        uint gas = gasleft();
        assertEq(store.get(0x0000000000000000000000000000000000000002), 20);
        assertLe(gas - gasleft(), 2400);
        assertEq(store.get(0x0000000000000000000000000000000000000613), 0);
    }

    function testSet() public {
        (address[] memory keys, uint96[] memory values) = store.entries();
        uint gas = gasleft();
        store.set(0x0000000000000000000000000000000000000002, 13);
        assertLe(gas - gasleft(), 5000);
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
        
        // get/set/remove 5 times
        address testKey = 0x0000000000000000000000000000000000000011;
        for (uint i = 1; i < 5; ++i) {
            store1.set(testKey, uint96(i));
            (address[] memory _keys, uint96[] memory _values) = store1.entries();
            assertEq(_values[0], uint96(i));
            assertEq(_keys[0], testKey);
            store1.remove(testKey);
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
        uint gas = gasleft();
        store.set(0x0000000000000000000000000000000000000006, 60);
        assertLe(gas - gasleft(), 30000);
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
        uint gas = gasleft();
        store.remove(0x0000000000000000000000000000000000000013);
        assertLe(gas - gasleft(), 3000);
        assertEq(store.get(0x0000000000000000000000000000000000000003), 30);
        store.remove(0x0000000000000000000000000000000000000003);
        assertEq(store.get(0x0000000000000000000000000000000000000003), 0);
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

    Store store1;

    function testCircularSingular() public {
        address testKey = 0x0000000000000000000000000000000000000011;
        store1.set(testKey, 1);
        store1.remove(testKey);
        store1.set(testKey, 1);
        (address[] memory _keys, uint96[] memory _values) = store1.entries();
    }

    function testCircularLast() public {
        address testKey = 0x0000000000000000000000000000000000000011;
        store1.set(testKey, 1);
        store1.set(0x0000000000000000000000000000000000000012, 1);
        store1.set(0x0000000000000000000000000000000000000013, 1);
        store1.remove(testKey);
        store1.set(testKey, 1);
        (address[] memory _keys, uint96[] memory _values) = store1.entries();
    }

    function testCircularSandwitch() public {
        address testKey = 0x0000000000000000000000000000000000000011;
        store1.set(0x0000000000000000000000000000000000000013, 1);
        store1.set(testKey, 1);
        store1.set(0x0000000000000000000000000000000000000012, 1);
        store1.remove(testKey);
        store1.set(testKey, 1);
        (address[] memory _keys, uint96[] memory _values) = store1.entries();
    }
}