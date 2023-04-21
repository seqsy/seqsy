// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

// Interface rollups must interface for registration with the Rollups.sol registry.
interface RollupInterface {
    // Get the current block number for the rollup. This can be dependent on the current L1 block
    // and/or the state stored on-chain on L1.
    function getBlockNumber() external;
}