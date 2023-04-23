// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./BLS.sol";
import "./Randomness.sol";

import "openzeppelin/token/ERC20/IERC20.sol";

contract SequencerSet {
    struct SequencerState {
        uint256 blockNumber;
        bytes32 aggregatedPublicKeyHash;
        uint256[4] aggregatedPublicKey;
    }
    IERC20 public StakedToken;
    Randomness public randomness;

    mapping(uint32 chainId => SequencerState[] sequencerStates)
        public SequencerStates;

    mapping(uint32 chainId => mapping(address operator => bytes32 pubKeyHash))
        public OperatorToPubKeyHash;
    mapping(uint32 chainId => mapping(bytes32 pubKeyHash => address operator))
        public PubKeyHashToOperator;
    mapping(bytes32 pubKeyHash => uint256[4] pubKey) public PubKeyHashToPubKey;

    mapping(uint32 chainId => mapping(address operator => uint256 stakeAmount))
        public OperatorStake;

    uint256 public minimumStakeThreshold;

    address[] public Operators;
    mapping(address operator => uint256 index) OperatorToIndex;

    event Staked(address staker, uint256 amount);
    event RegisterNewSequencer(
        bytes32 newAggregatedPublicKey,
        uint32 chainId,
        address operator
    );
    event UnregisterSequencer(
        bytes32 newAggregatedPublicKey,
        uint32 chainId,
        address operator
    );

    uint256[4] initAggregatedPublicKey;
    bytes32 immutable initAggregatedPublicKeyHashed;

    constructor(IERC20 _stakedToken, Randomness _randomness, uint256 _minimumStakeThreshold) {
        StakedToken = _stakedToken;
        randomness = _randomness;
        _minimumStakeThreshold = minimumStakeThreshold;

        initAggregatedPublicKey = [BLS.G2x0, BLS.G2x1, BLS.G2y0, BLS.G2y1];
        initAggregatedPublicKeyHashed = keccak256(
            abi.encode(
                initAggregatedPublicKey[0],
                initAggregatedPublicKey[1],
                initAggregatedPublicKey[2],
                initAggregatedPublicKey[3]
            )
        );
    }

    function stake(uint256 _stakedAmount, uint32 _chainId) public {
        bool success = StakedToken.transferFrom(
            msg.sender,
            address(this),
            _stakedAmount
        );
        require(success);

        OperatorStake[_chainId][msg.sender] += _stakedAmount;
        emit Staked(msg.sender, _stakedAmount);
    }

    function register(uint32 _chainId, uint256[4] calldata publicKey) external {
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
        PubKeyHashToPubKey[publicKeyHashed] = publicKey;

        bytes32 apkHash = keccak256(
            abi.encode(
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

        emit RegisterNewSequencer(apkHash, _chainId, msg.sender);
        Operators.push(msg.sender);
        OperatorToIndex[msg.sender] = Operators.length - 1;
    }

    function getLatestSequencerState(
        uint32 _chainId
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

    function deregister(uint32 _chainId) external {
        bytes32 userPubKeyHash = OperatorToPubKeyHash[_chainId][msg.sender];
        require(userPubKeyHash != 0);

        uint256[4] memory userPubKey = PubKeyHashToPubKey[userPubKeyHash];
        uint256 sequencerStateLength = SequencerStates[_chainId].length;

        require(sequencerStateLength != 0);

        SequencerState memory lastSequencerState = SequencerStates[_chainId][
            sequencerStateLength - 1
        ];

        (
            uint256 newApk0,
            uint256 newApk1,
            uint256 newApk2,
            uint256 newApk3
        ) = BLS.removePubkeyFromAggregate(
                userPubKey,
                lastSequencerState.aggregatedPublicKey
            );

        bytes32 aggregatedPublicKeyHash = keccak256(
            abi.encode([newApk0, newApk1, newApk2, newApk3])
        );

        if (lastSequencerState.blockNumber == block.number) {
            SequencerStates[_chainId][
                sequencerStateLength - 1
            ] = SequencerState({
                blockNumber: block.number,
                aggregatedPublicKey: [newApk0, newApk1, newApk2, newApk3],
                aggregatedPublicKeyHash: aggregatedPublicKeyHash
            });
        } else {
            SequencerStates[_chainId].push(
                SequencerState({
                    blockNumber: block.number,
                    aggregatedPublicKey: [newApk0, newApk1, newApk2, newApk3],
                    aggregatedPublicKeyHash: aggregatedPublicKeyHash
                })
            );
        }

        delete OperatorToPubKeyHash[_chainId][msg.sender];
        delete PubKeyHashToOperator[_chainId][userPubKeyHash];

        emit UnregisterSequencer(aggregatedPublicKeyHash, _chainId, msg.sender);
        Operators[OperatorToIndex[msg.sender]] = Operators[Operators.length - 1];
        Operators.pop();
    }

    // TODO(norswap): This only works under the condition that the sequencer set is stable.
    // Otherwise, we need to track the set off-chain, either via a subgraph queried by the node,
    // or directly via node logic (requires archive node access).
    function proposerForBlock(uint32 chainID, uint256 blockNumber) public view returns(address) {
        return Operators[uint256(randomness.randomnessForBlock(chainID, blockNumber)) % Operators.length];
    }
}
