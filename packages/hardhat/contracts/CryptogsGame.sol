pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CryptogsGame is VRFConsumerBase, Pausable {
    struct Game {
        bytes32 gameHash;
        address creator;
        address opponent;
        uint256[5] creatorTogs;
        uint256[5] opponentTogs;
        uint256 expirationBlock;
        bool completed;
    }

    mapping(uint256 => Game) public games;

    // The chance that a tog will flip (out of 255)
    uint256 flippiness = 64;

    // TODO: decide if we want chance to flip to increase in later rounds like in PizzaParlor.sol

    // The number of blocks that can pass until the opponent can no longer call playGame()
    uint256 blocksUntilExpiration = 40;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => uint256) private _vrfRequestIdToGameId;

    // TODO: add events

    constructor(address _vrfCoordinator, address _linkToken)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        // TODO: don't hardcode this stuff
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    function setupGame(uint256 _gameId, address _opponent, uint256[5] calldata _creatorTogs, uint256[5] calldata _opponentTogs) external {
        require(_creatorTogs.length == 5 && _opponentTogs.length == 5);
        // TODO: require that the creator owns at least one of all _creatorTogs and opponent owns at least one of all _opponentTogs
        // take into account that there could be more than one of the same tog in a stack

        games[_gameId] = Game(
            keccak256(abi.encodePacked(_opponent, _creatorTogs, _opponentTogs)),
            msg.sender,
            _opponent,
            _creatorTogs,
            _opponentTogs,
            block.number + 10,
            false
        );
    }

    function playGame(uint256 _gameId, uint256[5] calldata _creatorTogs, uint256[5] calldata _opponentTogs) external {
        // check that the game hash is the same to ensure this is the correct opponent and togs
        require(games[_gameId].gameHash == keccak256(abi.encode(msg.sender, _creatorTogs, _opponentTogs)));
        require(block.number <= games[_gameId].expirationBlock);
        require(!games[_gameId].completed);

        // TODO: require that the creator owns at least one of all _creatorTogs and opponent owns at least one of all _opponentTogs
        // take into account that there could be more than one of the same tog in a stack

        bytes32 requestId = _getRandomNumber();
        _vrfRequestIdToGameId[requestId] = _gameId;
    }

    // Once VRF generates a random number, this function will be called to continue the game logic
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 gameId = _vrfRequestIdToGameId[requestId];
        Game storage game = games[gameId];

        uint256 numFlipped = 0;
        bool[5] memory creatorTogFlipStatuses;
        bool[5] memory opponentTogFlipStatuses;

        uint256 roundId = 1;

        // TODO: decide if we want to have a max number of rounds or not
        while (numFlipped < 10) {
            // The creator goes first so if roundId is even, it's the opponent's turn
            address flipper = roundId % 2 == 0 ? game.opponent : game.creator;

            // TODO: store flip statuses in one array to remove duplicate for loop

            // loop through creator togs to decide the flips
            for (uint256 i = 0; i < 5; i++) {
                if (!creatorTogFlipStatuses[i]) {
                    // create a new random number for each round and tog
                    uint256 rand = uint256(keccak256(abi.encode(randomness, i, roundId)));

                    if (rand < flippiness) {
                        creatorTogFlipStatuses[i] = true;
                        _flip(gameId, roundId, flipper, game.creatorTogs[i]);
                        numFlipped++;
                    }
                }
            }

            // loop through opponent togs to decide the flips
            for (uint256 i = 0; i < 5; i++) {
                if (!opponentTogFlipStatuses[i]) {
                    // create a new random number for each round and tog
                    uint256 rand = uint256(keccak256(abi.encode(randomness, i, roundId)));

                    if (rand < flippiness) {
                        creatorTogFlipStatuses[i] = true;
                        _flip(gameId, roundId, flipper, game.creatorTogs[i]);
                        numFlipped++;
                    }
                }
            }

            roundId++;
        }

        game.completed = true;
    }

    function _flip(uint256 _gameId, uint256 _roundId, address _flipper, uint256 _togId) private {
        // TODO: transfer tog to flipper if it isn't their's already
        // TODO: emit Flip event
    }

    function _getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }
}