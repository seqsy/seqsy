// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "openzeppelin/token/ERC20/IERC20.sol";
import "./BLS.sol";

contract SequencerSet {
    struct SequencerState {
        uint256 blockNumber;
        uint256[4] aggregatedPublicKey;
        bytes32 aggregatedPublicKeyHash;
    }

    IERC20 public StakedToken;

    mapping(uint8 chainId => SequencerState[] sequencerStates)
        public SequencerStates;

    mapping(uint8 chainId => mapping(address operator => bytes32 pubKeyHash)) OperatorToPubKeyHash;
    mapping(uint8 chainId => mapping(bytes32 pubKeyHash => address operator)) PubKeyHashToOperator;

    mapping(uint8 chainId => mapping(address operator => uint256 stakeAmount))
        public OperatorStake;

    uint256 public minimumStakeThreshold;

    event Staked(address staker, uint256 amount);
    event RegisterNewSequencer(bytes32 newAggregatedPublicKey, uint8 chainId);
    event UnregisterSequencer(bytes32 newAggregatedPublicKey, uint8 chainId);

    uint256[4] initAggregatedPublicKey;
    bytes32 initAggregatedPublicKeyHashed;

    constructor(IERC20 _stakedToken, uint256 _minimumStakeThreshold) {
        StakedToken = _stakedToken;
        _minimumStakeThreshold = minimumStakeThreshold;

        initAggregatedPublicKey = [BLS.G2x0, BLS.G2x1, BLS.G2y0, BLS.G2y1];
        initAggregatedPublicKeyHashed = keccak256(
            abi.encodePacked(
                initAggregatedPublicKey[0],
                initAggregatedPublicKey[1],
                initAggregatedPublicKey[2],
                initAggregatedPublicKey[3]
            )
        );
    }

    function stake(uint256 _stakedAmount, uint8 _chainId) public {
        bool success = StakedToken.transferFrom(
            msg.sender,
            address(this),
            _stakedAmount
        );
        require(success);

        OperatorStake[_chainId][msg.sender] += _stakedAmount;
        emit Staked(msg.sender, _stakedAmount);
    }

    function register(uint8 _chainId, uint256[4] calldata publicKey) external {
        require(OperatorStake[_chainId][msg.sender] >= minimumStakeThreshold);

        uint256 sequencerStateLength = SequencerStates[_chainId].length;
        SequencerState memory latestSequencerState;

        if (sequencerStateLength == 0) {
            latestSequencerState = SequencerState({
                blockNumber: block.number - 1,
                aggregatedPublicKey: initAggregatedPublicKey,
                aggregatedPublicKeyHash: initAggregatedPublicKeyHashed
            });
        } else {
            latestSequencerState = SequencerStates[_chainId][
                sequencerStateLength - 1
            ];
        }
        uint256[6] memory _aggregatedPublicKey = BLS.addJac(
            [publicKey[0], publicKey[1], publicKey[2], publicKey[3], 1, 0],
            [
                latestSequencerState.aggregatedPublicKey[0],
                latestSequencerState.aggregatedPublicKey[1],
                latestSequencerState.aggregatedPublicKey[2],
                latestSequencerState.aggregatedPublicKey[3],
                1,
                0
            ]
        );

        bytes32 publicKeyHashed = keccak256(
            abi.encode(publicKey[0], publicKey[1], publicKey[2], publicKey[3])
        );

        require(PubKeyHashToOperator[_chainId][publicKeyHashed] == address(0));
        require(OperatorToPubKeyHash[_chainId][msg.sender] == 0);

        OperatorToPubKeyHash[_chainId][msg.sender] = publicKeyHashed;
        PubKeyHashToOperator[_chainId][publicKeyHashed] = msg.sender;

        bytes32 apkHash = keccak256(
            abi.encodePacked(
                _aggregatedPublicKey[0],
                _aggregatedPublicKey[1],
                _aggregatedPublicKey[2],
                _aggregatedPublicKey[3]
            )
        );

        if (latestSequencerState.blockNumber == block.number) {
            // update this array
            SequencerStates[_chainId][
                sequencerStateLength - 1
            ] = SequencerState({
                blockNumber: block.number,
                aggregatedPublicKey: [
                    _aggregatedPublicKey[0],
                    _aggregatedPublicKey[1],
                    _aggregatedPublicKey[2],
                    _aggregatedPublicKey[3]
                ],
                aggregatedPublicKeyHash: apkHash
            });
        } else {
            // update this array
            SequencerStates[_chainId].push(
                SequencerState({
                    blockNumber: block.number,
                    aggregatedPublicKey: [
                        _aggregatedPublicKey[0],
                        _aggregatedPublicKey[1],
                        _aggregatedPublicKey[2],
                        _aggregatedPublicKey[3]
                    ],
                    aggregatedPublicKeyHash: apkHash
                })
            );
        }

        emit RegisterNewSequencer(apkHash, _chainId);
    }

    function getLatestSequencerState(
        uint8 _chainId
    ) external view returns (SequencerState memory) {
        uint256 sequencerStateLength = SequencerStates[_chainId].length;
        if (sequencerStateLength == 0) {
            return
                SequencerState({
                    blockNumber: block.number,
                    aggregatedPublicKey: initAggregatedPublicKey,
                    aggregatedPublicKeyHash: initAggregatedPublicKeyHashed
                });
        }

        SequencerState memory latestSequencerState = SequencerStates[_chainId][
            sequencerStateLength - 1
        ];

        // if latest sequencer state is in the current block, we get
        // the state from one block before
        if (latestSequencerState.blockNumber == block.number) {
            return SequencerStates[_chainId][sequencerStateLength - 2];
        }

        return latestSequencerState;
    }

    function deregister(
        uint8 _chainId,
        uint256[4] calldata _aggregatedPublicKey
    ) external {}
}
