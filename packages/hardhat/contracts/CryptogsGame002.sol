// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// Cryptogs Reborn Game contract v0.2
// updated by 0xAA, 2022, 03, 08
// Development / Design / Coordination :@cosmoburn, @0xAA_Science, @deepe_eth, @steve0xp, TylerS, @beastadon, @OrHalldor, @Thisisnottap
contract CryptogsGame is ERC1155Holder, VRFConsumerBase, Pausable, Ownable {
    struct Game {
        uint gameState;
        address creator;
        address opponent;
        uint256[] creatorTogs;
        uint256[] creatorTogsAmount;
        uint256[] opponentTogs;
        uint256[] opponentTogsAmount;
        address nextMover;
        uint256 expirationBlock; 
        uint256 round; // game round
        bool withdrawed; 
    }

    mapping(uint256 => Game) public games;
    uint256 public gameId = 0;
    // CryptogsReborn NFT address on Polygon
    address public CryptogsAddress;
    IERC1155 Cryptogs;

    // The chance that a tog will flip (out of 255)
    uint256 flippiness = 64;
    uint256 flippiness_total = 255;
    // The number of blocks that can pass until the opponent can no longer call playGame(), update to 25 blocks (~ 6 mins)
    uint256 blocksUntilExpiration = 25;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    struct SlammerRequest {
        uint256 gameId;
        address player;
    }
    mapping(bytes32 => SlammerRequest) private _vrfRequestIdToSlammerRequest;

    // constructor
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */

    // 0xAA update: keyHash is no longer hardcoded, and add cryptogs contract address to verify the crytogs NFTs are legit.

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, address _Cryptogs)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        keyHash = _keyHash;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (on polygon network)
        CryptogsAddress = _Cryptogs; // set cryptogsReborn contract address
        Cryptogs = IERC1155(_Cryptogs);
    }

    // function to get sum of array
    function getArraySum(uint[] memory _array) 
            public 
            pure 
            returns (uint sum_) 
        {
            sum_ = 0;
            for (uint i = 0; i < _array.length; i++) {
                sum_ += _array[i];
            }
        }


    // gameInit event: player 0 set up the game
    event gameInit(uint256 indexed gameId, address indexed sender, uint256 indexed expirationBlock);

    // player 0 init Game 
    function initGame(uint256[] calldata _creatorTogs, uint256[] calldata _amounts) public {
        require(_creatorTogs.length == _amounts.length);
        require(_creatorTogs.length <= 5);
        require(getArraySum(_amounts) == 5);
        // transfer 5 Pogs to game
        Cryptogs.safeBatchTransferFrom(_msgSender(), address(this), _creatorTogs, _amounts, "");
        // set gameState to 1: initGame state
        uint gameState = 1;
        uint256 expirationBlock = block.number + blocksUntilExpiration;
        uint256[] memory tmp0 = new uint256[](5);
        uint256[] memory tmp1 = new uint256[](5);

        // create game struct
        Game memory game0 = Game({
            gameState: gameState,
            creator: _msgSender(),
            opponent: address(0),
            creatorTogs: _creatorTogs,
            creatorTogsAmount: _amounts,
            opponentTogs: tmp0,
            opponentTogsAmount: tmp1,
            nextMover: _msgSender(),
            expirationBlock: expirationBlock,
            round: 1,
            withdrawed: false
            });
        // push current game to array
        games[gameId] = game0;

        emit gameInit(gameId, _msgSender(), expirationBlock);

        gameId += 1;

    }

    // gameJoin event: player 1 joins the game
    event gameJoin(uint256 indexed GameId, address indexed sender, uint256 indexed expirationBlock);

    // player 1 join Game 
    function joinGame(uint256 _gameId, uint256[] calldata _joinTogs, uint256[] calldata _amounts) public {
        require(_gameId <= gameId);
        require(games[_gameId].gameState == 1); // game state check
        require(block.number <= games[_gameId].expirationBlock); // game not expiration
        require(_joinTogs.length == _amounts.length); // two array have same length
        require(_joinTogs.length <= 5);
        require(getArraySum(_amounts) == 5); // transfer amount = 5
        require(games[_gameId].creator != _msgSender()); // player0 != player1

        uint256 expirationBlock = block.number + blocksUntilExpiration;

        // fill opponent information to game
        Game storage game0 = games[_gameId];
        game0.opponent = _msgSender();
        game0.opponentTogs = _joinTogs;
        game0.opponentTogsAmount = _amounts;
        game0.expirationBlock = expirationBlock; // update expirationBlock
        game0.gameState = 2; // change game state to 2: game ready to SLAMMER!

        emit gameJoin(_gameId, _msgSender(), expirationBlock);
    }
    
    // Slammer event:
    event Slammer(address indexed Sender, bytes32 indexed RequestId, uint256 indexed ExpirationBlock);
    // Slammer Time: Next Mover Throw Slammer, which generate random number from Chainlink VRF and flip POGs randomly
    function playGame(uint256 _gameId) public {
        require(_gameId <= gameId);
        require(games[_gameId].gameState == 2); // game state check
        require(block.number <= games[_gameId].expirationBlock); // game not expiration
        require(games[_gameId].nextMover == _msgSender()); // next Player is msg.sender
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        Game storage game0 = games[_gameId];

        // SLAMMER TIME!
        // get random number
        bytes32 requestId = requestRandomness(keyHash, fee);
        _vrfRequestIdToSlammerRequest[requestId] = SlammerRequest(_gameId,_msgSender());

        uint256 expirationBlock = block.number + blocksUntilExpiration;
        game0.expirationBlock = expirationBlock; // update expirationBlock

        // update next mover
        if(game0.creator == _msgSender()){
            game0.nextMover = game0.opponent;
        }else{
            game0.nextMover = game0.creator;
        }

        emit Slammer(_msgSender(), requestId, expirationBlock);
    }


    event FlipTogs(address indexed player, uint256 indexed gameId, uint256 indexed gameRound, uint256[] flippedTogs, uint256[] flippedAmounts);     
    // Once VRF generates a random number, this function will be called to continue the game logic
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // get slammer request by vrf requestId
        SlammerRequest memory slammerRequest = _vrfRequestIdToSlammerRequest[requestId];
        address _player = slammerRequest.player;
        uint256 _gameId = slammerRequest.gameId;
        // get game object
        Game storage game0 = games[_gameId];

        // flipped togs
        uint256[] memory flippedTogs;
        uint256[] memory flippedAmounts;
        uint256 _rand;
        // flip togs of player 0
        for (uint256 i = 0; i < game0.creatorTogs.length; i++) {
            if(game0.creatorTogsAmount[i] >0){
                _rand = uint256(keccak256(abi.encode(randomness, i))) % flippiness_total;
                if(_rand < randomness){
                    flippedTogs[i] = game0.creatorTogs[i];
                    flippedAmounts[i] = 1;
                    game0.creatorTogsAmount[i] -= 1;
                }else{
                    flippedTogs[i] = game0.creatorTogs[i];
                    flippedAmounts[i] = 0;

                }
            }
        }

        // flip togs of player 1

        for (uint256 i = 0; i < game0.opponentTogs.length; i++) {
            if(game0.opponentTogsAmount[i] >0){
                _rand = uint256(keccak256(abi.encode(randomness, i+5))) % flippiness_total;
                if(_rand < randomness){
                    // when flip
                    flippedTogs[i+5] = game0.opponentTogs[i];
                    flippedAmounts[i+5] = 1;
                    game0.opponentTogsAmount[i] -= 1;
                }else{
                    flippedTogs[i+5] = game0.opponentTogs[i];
                    flippedAmounts[i+5] = 0;

                }
            }
        }

        if(getArraySum(game0.creatorTogsAmount) == 0 && getArraySum(game0.opponentTogsAmount) == 0){
            game0.gameState = 3;
        }
        game0.round += 1;
        // transfer flipped Pog 

        Cryptogs.safeBatchTransferFrom(address(this), _player, flippedTogs, flippedAmounts, "");
        emit FlipTogs(_player, _gameId, game0.round, flippedTogs, flippedAmounts);
    }

    event WithdrawTogs (uint256 indexed GameId, address indexed creator, address indexed opponent);
    // Withdraw Togs when game completed or expired
    function withdrawTogs (uint256 _gameId) public {
        require(_gameId <= gameId);
        require(games[_gameId].gameState == 3 || games[_gameId].expirationBlock < block.number); // game finished or expired
        require(games[_gameId].withdrawed == false);

        Cryptogs.safeBatchTransferFrom(address(this), games[_gameId].creator, games[_gameId].creatorTogs, games[_gameId].creatorTogsAmount, "");
        Cryptogs.safeBatchTransferFrom(address(this), games[_gameId].opponent, games[_gameId].opponentTogs, games[_gameId].opponentTogsAmount, "");
        
        // end the game
        games[_gameId].withdrawed = true;
        games[_gameId].gameState = 4;
        
        uint256[] memory tmp0 = new uint256[](5);
        uint256[] memory tmp1 = new uint256[](5);

        games[_gameId].creatorTogsAmount = tmp0;
        games[_gameId].opponentTogsAmount = tmp1;

        emit WithdrawTogs(_gameId, games[_gameId].creator, games[_gameId].opponent);

    }

    event WithdrawToken(address indexed TokenContract, uint256 indexed Amount);
    // withdraw token: LINK (only owner)
    function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
        emit WithdrawToken(_tokenContract, _amount);
    }
    
    // withdraw ETH/Polygon
    function withdrawETH() public onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }


    



}