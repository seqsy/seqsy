// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

import "./RollupInterface.sol";

// Rollup interface implementation that maps L2 blocks one for one to L1 blocks.
contract OneForOneRollupImplem is RollupInterface {
    function getL2BlockNumber() view external returns(uint256) {
        return block.number;
    }

    function getL1BlockNumberForL2BlockNumber(uint256 l2BlockNumber) pure external returns(uint256) {
        return l2BlockNumber;
    }
}