// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

import "./Rollups.sol";

// This is a randomness beacon used to determine the sequencer that will get to sequence a given
// rollup block.
//
// We currently use the L1 blockhash as a randomness source, but that's not good enough, as
// validators can easily bias it. Instead we should use Chee's Natto protocol off-chain
// (+ post the updated randomness along with the proposal on-chain).
contract Randomness {

    Rollups public rollups;

    constructor(Rollups _rollups) {
        rollups = _rollups;
    }

    // This is the seed for the randomness beacon for the given chain.
    // NOTE(norswap): The L1 chain validator can bias this.
    function randomnessForBlock(uint32 chainID, uint256 blockNumber) public view returns (bytes32) {
        uint256 l1BlockNumber =
            rollups.implementations(chainID).getL1BlockNumberForL2BlockNumber(blockNumber);
        return keccak256(abi.encodePacked(l1BlockNumber, chainID, blockNumber));
    }
}