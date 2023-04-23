// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "../../src/SequencerSet.sol";

contract MockSequencerSet is SequencerSet {
    constructor(
        IERC20 _stakedToken,
        uint256 _minimumStakeThreshold
    // bogus Randomness contract, but it's ok
    ) SequencerSet(_stakedToken, Randomness(address(0)), _minimumStakeThreshold) {}

    function getSequencerState(
        uint32 _chainId,
        uint256 index
    ) public view returns (SequencerState memory state) {
        return SequencerStates[_chainId][index];
    }

    function getPubKeyHashToPubKey(
        bytes32 pubKeyHash
    ) public view returns (uint256[4] memory) {
        return PubKeyHashToPubKey[pubKeyHash];
    }

    function getInitAggregatedPublicKey()
        public
        view
        returns (uint256[4] memory)
    {
        return initAggregatedPublicKey;
    }

    function getInitAggregatedPublicKeyHashed() public view returns (bytes32) {
        return initAggregatedPublicKeyHashed;
    }
}
