// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.0;

import "../DataStream.sol";
import "../L1BlockHistory.sol";
import "../OneForOneRollupImplem.sol";
import "../Randomness.sol";
import "../Rollups.sol";

import "forge-std/Script.sol";

contract DeployLocal is Script {
    bytes32 private constant salt = bytes32(uint256(4269));

    function run() external {
        vm.startBroadcast();

        L1BlockHistory l1BlockHistory = new L1BlockHistory();
        Rollups rollups = new Rollups();
        Randomness randomness = new Randomness(rollups);
        // TODO deploy sequencer registry
        DataStream dataStream = new DataStream(address(0));

        // Initialize our test rollup.
        RollupInterface rollup = new OneForOneRollupImplem();
        uint32 chainID = 424242;
        rollups.register(chainID, address(rollup));

        console2.log("L1BlockHistory address",          address(l1BlockHistory));
        console2.log("Randomness address",              address(randomness));
        console2.log("Rollups address",                 address(rollups));
        console2.log("DataStream address",              address(dataStream));
        console2.log("OneForOneRollupImplem address",   address(rollup));

        vm.stopBroadcast();
    }
}

contract DeployPublic is Script {
    bytes32 private constant salt = bytes32(uint256(4269));

    function run() external {
        vm.startBroadcast();

        // Using CREATE2 (specifying salt) makes deployment address predictable no matter the chain,
        // if the bytecode does not change. (Note that Foundry omits the matadata hash by default:
        // https://github.com/foundry-rs/foundry/pull/1180)

        // Not used for local deployments because it needs the CREATE2 deployer deployed at
        // 0x4e59b44847b379578588920ca78fbf26c0b4956c and that's not the case on the Anvil chain.

        L1BlockHistory l1BlockHistory = new L1BlockHistory{salt: salt}();
        Rollups rollups = new Rollups{salt: salt}();
        Randomness randomness = new Randomness{salt: salt}(rollups);
        // TODO deploy sequencer registry
        DataStream dataStream = new DataStream{salt: salt}(address(0));

        // Initialize our test rollup.
        RollupInterface rollup = new OneForOneRollupImplem{salt: salt}();
        uint32 chainID = 424242;
        rollups.register(chainID, address(rollup));

        console2.log("L1BlockHistory address",          address(l1BlockHistory));
        console2.log("Randomness address",              address(randomness));
        console2.log("Rollups address",                 address(rollups));
        console2.log("DataStream address",              address(dataStream));
        console2.log("OneForOneRollupImplem address",   address(rollup));

        console2.log("Multicall3 address", 0xcA11bde05977b3631167028862bE2a173976CA11);

        vm.stopBroadcast();
    }
}
