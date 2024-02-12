// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract StructDefiner {
    struct MyStruct {
        uint256 someField; // 32 byte
        address someAddress; // 20 byte
        uint128 someOtherField; // 16 byte
        uint128 oneMoreField; // 16 byte
    }
}

contract Storage {
    StructDefiner.MyStruct[] internal structs;

    // Function to retrieve a struct by its index in the array and return it as a bytes array
    function getStructByIdx(uint256 idx) external view returns (bytes memory) {
        // Ensure the requested index is within bounds of the array
        require(idx < structs.length, "Index out of bounds");

        // Access the struct at the specified index
        StructDefiner.MyStruct storage s = structs[idx];

        // Initialize a bytes array with sufficient size to hold all struct fields
        bytes memory b = new bytes(96); 
        assembly {
            // Load and store the first field of the struct (someField) directly
            mstore(add(b, 32), sload(s.slot))
            // Extract the address value, ensuring only the relevant bytes are included
            let someAddressValue := and(sload(add(s.slot, 1)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(b, 64), someAddressValue)
            // Load the combined storage of the two uint128 fields
            let combinedFields := sload(add(s.slot, 2))
            // Extract the first uint128 field (someOtherField)
            let someOtherField := and(combinedFields, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            // Extract and shift the second uint128 field (oneMoreField) to align it correctly
            let oneMoreField := shl(128, and(combinedFields, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000))
            // Combine the two uint128 fields back together for storage
            combinedFields := or(oneMoreField, someOtherField)
            // Store the combined uint128 fields in the bytes array
            mstore(add(b, 96), combinedFields)
        }
        return b;
    }
}

contract Controller {
    // Reference to the Storage contract
    Storage internal strg;

    // Constructor to set the Storage contract address
    constructor(address _storage) {
        strg = Storage(_storage);
    }

    // Function to retrieve and reconstruct a struct from the bytes array returned by Storage.getStructByIdx
    function getStruct(uint256 idx) public view returns (StructDefiner.MyStruct memory myStruct) {

        bytes memory b = strg.getStructByIdx(idx);
        assembly {
            // Allocate memory for the struct to be reconstructed
            myStruct := mload(0x40)
            // Adjust the free memory pointer
            mstore(0x40, add(myStruct, 128))
            // Reconstruct the someField from the bytes array
            mstore(myStruct, mload(add(b, 32)))
            // Reconstruct the someAddress from the bytes array
            mstore(add(myStruct, 32), mload(add(b, 64)))
            // Extract the combined uint128 fields
            let combinedFields := mload(add(b, 96))
            // Reconstruct the someOtherField from the combined uint128 fields
            mstore(add(myStruct, 64), and(combinedFields, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // Reconstruct the oneMoreField by shifting the combined uint128 fields
            mstore(add(myStruct, 96), shr(128, combinedFields))
        }
    }
}