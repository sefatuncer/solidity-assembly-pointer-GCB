//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract A {
    mapping (address => uint256) values;

    function getValue(address _addr) public pure returns (bytes32 storagePointer) {
        assembly {
            // Calculate the slot for the given key `_addr` in the `values` mapping
            // Slot calculation: keccak256(abi.encodePacked(key, slot))
            // where key is `_addr` and slot for `values` is assumed to be 0.
            let slot := mload(0x40) // Free memory pointer
            mstore(slot, _addr) // Store `_addr` at the free memory slot
            mstore(add(slot, 0x20), 0) // Store the mapping slot (0) after the address
            storagePointer := keccak256(slot, 0x40) // Perform keccak256 over the 64 bytes
        }
    }
}