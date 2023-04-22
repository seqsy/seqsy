// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/FakeWeth.sol";
import "./Utils.sol";
import "../src/BLS.sol";
import "./mock/MockSequencerSet.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract SequencerSetTest is Test {
    Utils internal utils;
    Weth weth;
    MockSequencerSet sequencerSet;

    address internal alice;
    uint256[4] internal alicePublicKey = [111, 222, 333, 444];
    bytes32 internal alicePublicKeyHash =
        keccak256(
            abi.encode(
                alicePublicKey[0],
                alicePublicKey[1],
                alicePublicKey[2],
                alicePublicKey[3]
            )
        );
    address payable[] internal users;
    uint32 _chainId = 100;

    function setUp() public {
        weth = new Weth();
        sequencerSet = new MockSequencerSet(IERC20(weth), 1);

        utils = new Utils();
        users = utils.createUsers(1);
        alice = users[0];

        weth.mint(alice, 100 ether);

        vm.prank(alice);
        weth.approve(address(sequencerSet), type(uint256).max);
    }

    function testStake() public {
        vm.prank(alice);
        sequencerSet.stake(10 ether, _chainId);

        uint256 balanceAfter = weth.balanceOf(alice);
        assertEq(balanceAfter, 90 ether);

        uint256 stakeAfter = sequencerSet.OperatorStake(_chainId, alice);
        assertEq(stakeAfter, 10 ether);
    }

    function testRegister() public {
        vm.roll(100);
        vm.prank(alice);
        sequencerSet.register(_chainId, alicePublicKey);

        MockSequencerSet.SequencerState memory state = sequencerSet
            .getSequencerState(_chainId, 0);

        assertEq(state.blockNumber, 100);

        uint256[6] memory aggregatedPublicKey = BLS.addJac(
            [
                alicePublicKey[0],
                alicePublicKey[1],
                alicePublicKey[2],
                alicePublicKey[3],
                1,
                0
            ],
            [BLS.G2x0, BLS.G2x1, BLS.G2y0, BLS.G2y1, 1, 0]
        );

        bytes32 aggregatedPublicKeyHash = keccak256(
            abi.encode(
                aggregatedPublicKey[0],
                aggregatedPublicKey[1],
                aggregatedPublicKey[2],
                aggregatedPublicKey[3]
            )
        );

        assertEq(state.aggregatedPublicKey[0], aggregatedPublicKey[0]);
        assertEq(state.aggregatedPublicKey[1], aggregatedPublicKey[1]);
        assertEq(state.aggregatedPublicKey[2], aggregatedPublicKey[2]);
        assertEq(state.aggregatedPublicKey[3], aggregatedPublicKey[3]);

        assertEq(state.aggregatedPublicKeyHash, aggregatedPublicKeyHash);

        assertEq(
            sequencerSet.OperatorToPubKeyHash(_chainId, alice),
            alicePublicKeyHash
        );
        assertEq(
            sequencerSet.PubKeyHashToOperator(_chainId, alicePublicKeyHash),
            alice
        );

        uint256[4] memory _alicePubKey = sequencerSet.getPubKeyHashToPubKey(alicePublicKeyHash);
        assertEq(_alicePubKey[0], alicePublicKey[0]);
        assertEq(_alicePubKey[1], alicePublicKey[1]);
        assertEq(_alicePubKey[2], alicePublicKey[2]);
        assertEq(_alicePubKey[3], alicePublicKey[3]);
    }

    function testDeregister() public {
        vm.prank(alice);
        sequencerSet.register(_chainId, alicePublicKey);

        vm.prank(alice);
        sequencerSet.deregister(_chainId);

        MockSequencerSet.SequencerState memory state = sequencerSet
            .getSequencerState(_chainId, 0);

        //  assertEq(state.aggregatedPublicKey[0], aggregatedPublicKey[0]);
        // assertEq(state.aggregatedPublicKey[1], aggregatedPublicKey[1]);
        // assertEq(state.aggregatedPublicKey[2], aggregatedPublicKey[2]);
        // assertEq(state.aggregatedPublicKey[3], aggregatedPublicKey[3]);

        assertEq(state.aggregatedPublicKeyHash, sequencerSet.getInitAggregatedPublicKeyHashed());
    }
}
