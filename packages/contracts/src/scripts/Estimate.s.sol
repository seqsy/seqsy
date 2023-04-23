// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../DataStream.sol";

contract Estimate is Script {

    function estimate(address stream) public {
        uint256 gasEstimate = gasleft();
        DataStream(stream).propose(4242, 0, bytes32(uint256(0)), bytes("hello world"));
        gasEstimate = gasEstimate - gasleft();
        console2.log("gas estimate:", gasEstimate);
    }
}