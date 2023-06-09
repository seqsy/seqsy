// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

// This records proposed blocks as well as their "approvals" (claims of aggregated BLS sequencer
// signatures, to be checked off-chain.
//
// This file might seem sparse, but we don't actually need a lot of checks here, because the
// sequencers will sort out which proposals are valid and which ones are not, as well as which
// approvals (signatures) are valid or not.
contract DataStream {

    address public validatorSet;

    constructor(address _validatorSet) {
        validatorSet = _validatorSet;
    }

    event Proposed(
        uint32 indexed chainID,
        uint256 blockNumber,
        address proposer,
        bytes32 blockhash);

    event Approved(
        uint32  indexed chainID,
        uint256 indexed blockNumber,
        bytes32 indexed blockhash);

    function propose(
        uint32 chainID,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes calldata /* block */)
      public {
        emit Proposed(chainID, blockNumber, msg.sender, blockHash);
    }

    function approve(
        uint32 chaindID,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes calldata /* aggregatedSignature */)
      public {
        // TODO(norswap):
        //  Validate the signature format — this is not safety-critical, but saves work for
        //  the sequencers by avoiding spurious Approved events.
        emit Approved(chaindID, blockNumber, blockHash);
    }
}