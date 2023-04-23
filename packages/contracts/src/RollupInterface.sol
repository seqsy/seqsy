// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

// Interface rollups must interface for registration with the Rollups.sol registry.
interface RollupInterface {
    // Get the current L2 block number. This can be dependent on the current L1 block and/or the
    // state stored on-chain on L1.
    function getL2BlockNumber() external view returns(uint256);

    // Get the L1 block number corresponding to the given L2 block number. The result can be
    // dependent on the state stored on-chain on L1.
    function getL1BlockNumberForL2BlockNumber(uint256 l2BlockNumber) external view returns(uint256);
}