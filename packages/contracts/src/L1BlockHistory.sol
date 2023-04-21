// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

// This contract records the L1 block hash history (on L1). Since only the 256 last blockhashes
// are available via the BLOCKHASH opcode, failure to call the "recordBlockHash" function for
// 256 blocks or more means the blockhashes are lost.
//
// Instead we will pretend that the blockhash for these block numbers are the hashes of the
// previous blockhash (which may itself have been obtained by the same method).
//
// An alternative method would be to allow the sequencer to fill in the blockhashes "backwards"
// by providing the preimage of a known blockhash and extracting the parent hash from there.
// This is probably the better solution, but this is a hackaton and we don't have time for these
// shenanigans.
contract L1BlockHistory {

    error AlreadyInitialized();

    uint256 public lastBlockNumber;

    mapping(uint256 /* blockNumber */ => bytes32 /* blockHash */) private blockHashes;

    function initialize() external {
        if (lastBlockNumber != 0) revert AlreadyInitialized();
        blockHashes[block.number - 1] = blockhash(block.number - 1);
        lastBlockNumber = block.number - 1;
    }

    // TODO(norswap):
    //   Enable gas metering so that if we haven't recorded the block number in a long
    //   time, we don't brick the contract & are still able to make progress.
    function recordBlockHash() external {
        uint256 currentBlock = block.number - 1;
        if (lastBlockNumber == currentBlock) return;

        uint256 last = lastBlockNumber;
        while (last < block.number - 256) {
            // Opportunity to record hash was lost, set to hash of previous hash instead.
            blockHashes[last] = keccak256(abi.encodePacked(blockHashes[last - 1]));
            ++last;
        }
        while (last <= currentBlock) {
            blockHashes[last] = blockhash(last);
            ++last;
        }
    }
}