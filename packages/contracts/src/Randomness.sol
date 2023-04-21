// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

// This is a randomness beacon used to determine the sequencer that will get to sequence a given
// rollup block.
contract Randomness {

    error AlreadyInitialized(uint32 chainID);
    error NotInitialized(uint32 chainID);

    mapping(uint32 /* chaindID */ => bytes32 /* seed */) seeds;

    function initialize(uint32 chainID) public {
        if (seeds[chainID] == 0) revert AlreadyInitialized(chainID);
        seeds[chainID] = blockhash(block.number - 1);
    }

    function randomnessForBlock(uint32 chainID, uint256 blockNumber) public view returns (bytes32) {
        bytes32 seed = seeds[chainID];
        if (seed == 0) revert NotInitialized(chainID);
        return keccak256(abi.encodePacked(seed, chainID, blockNumber));
    }
}