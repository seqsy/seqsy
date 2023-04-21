// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

import "./RollupInterface.sol";

// This is a rollup registry, which registers custom hooks for rollup chains.
contract Rollups {

    error AlreadyRegistered(uint32 chainID);

    mapping(uint32 /* chainID */ => RollupInterface) public implementations;

    // TODO(norswap):
    //   This is too easy to grief, we should identify the rollups with a bytes32
    //   that is the hash of a well known string key. Let's keep simple for the hackaton.
    function register(uint32 chainID, address rollupImplem) public {
        address current = address(implementations[chainID]);
        if (current != address(0)) revert AlreadyRegistered(chainID);
        implementations[chainID] = RollupInterface(rollupImplem);
    }
}