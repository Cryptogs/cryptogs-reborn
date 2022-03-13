// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// Cryptogs Reborn Game contract v0.3
// updated by 0xAA, 2022, 03, 13
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
        uint256 expirationBlock; 
        bool withdrawed; 
    }

    mapping(uint256 => Game) public games;
    uint256 public gameId = 0;
    // CryptogsReborn NFT address on Polygon
    address public CryptogsAddress;
    IERC1155 Cryptogs;

    // The number of blocks that can pass until the opponent can no longer call playGame(), update to 25 blocks (~ 6 mins)
    uint256 blocksUntilExpiration = 25;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => uint256) private _vrfRequestIdToGameId;

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
    function getArraySum(uint256[] memory _array) 
            public 
            pure 
            returns (uint256 sum_) 
        {
            sum_ = 0;
            for (uint i = 0; i < _array.length; i++) {
                sum_ += _array[i];
            }
        }

    // function to flatten a ERC1155 (tokenId, amount) array

    function getArraySum(uint256[] memory _tokenId,  uint256[] memory _amount) public pure returns (uint256[] memory flatId, uint256[] memory flatAmount){
        require(_tokenId.length == _amount.length);
        uint256[] memory flatId; 
        uint256[] memory flatAmount;
        uint j = 0;
        for (uint i = 0; i < _tokenId.length; i++){
            while(_amount[i] != 0){
                flatId[j] = _tokenId[i];
                flatAmount[j] =1;
                _amount[i] -=1;
                j += 1;
            }
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
            expirationBlock: expirationBlock,
            withdrawed: false
            });
        // push current game to array
        games[gameId] = game0;

        emit gameInit(gameId, _msgSender(), expirationBlock);

        gameId += 1;

    }

    // gameJoin event: player 1 joins the game
    event gameJoin(uint256 indexed GameId, address indexed player0, address indexed player1, bytes32 RequestId);

    // player 1 join Game 
    function joinPlay(uint256 _gameId, uint256[] calldata _joinTogs, uint256[] calldata _amounts) public {
        require(_gameId <= gameId);
        require(games[_gameId].gameState == 1); // game state check
        require(block.number <= games[_gameId].expirationBlock); // game not expiration
        require(_joinTogs.length == _amounts.length); // two array have same length
        require(_joinTogs.length <= 5);
        require(getArraySum(_amounts) == 5); // transfer amount = 5
        require(games[_gameId].creator != _msgSender()); // player0 != player1
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        // fill opponent information to game
        Game storage game0 = games[_gameId];
        game0.opponent = _msgSender();
        game0.opponentTogs = _joinTogs;
        game0.opponentTogsAmount = _amounts;
        game0.gameState = 2; // change game state to 2: finished

        // SLAMMER TIME!
        // get random number
        bytes32 requestId = requestRandomness(keyHash, fee);
        _vrfRequestIdToGameId[requestId] = _gameId;
        
        emit gamePlay(_gameId, game0.creator, _msgSender(), RequestId);

    }


    event FlipTogs(uint256 indexed gameId, address indexed player0,  address indexed player1, uint256[] flippedTogs, uint256[] amountPlayer0, uint256[] amountPlayer1);     
    // Once chainlink VRF generates a random number, this function will be called automatically to transfer flipped togs to players.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // get gameId by vrf requestId
        uint256 _gameId = _vrfRequestIdToGameId[requestId];
        // get game object
        Game storage game0 = games[_gameId];

        // flipped togs
        uint256[] memory flippedTogs;
        uint256[] memory amountPlayer0;
        uint256[] memory amountPlayer1;

        uint256 _rand;
        uint256 j = 0;

        // flip togs of player 0
        for (uint256 i = 0; i < game0.creatorTogs.length; i++) {
            while(game0.creatorTogsAmount[i] != 0){
                _rand = uint256(keccak256(abi.encode(randomness, j))) % 2;
                flippedTogs[j] = game0.creatorTogs[i];
                if(_rand == 0){
                    amountPlayer0[j] =1;
                }else{
                    amountPlayer1[j] =1;
                }
                game0.creatorTogsAmount[i] -=1;
                j += 1;
            }
        }
        // flip togs of player 1
        for (uint256 i = 0; i < game0.opponentTogs.length; i++) {
            while(game0.opponentTogsAmount[i] != 0){
                _rand = uint256(keccak256(abi.encode(randomness, j))) % 2;
                flippedTogs[j] = game0.opponentTogs[i];
                if(_rand == 0){
                    amountPlayer0[j] =1;
                }else{
                    amountPlayer1[j] =1;
                }
                game0.opponentTogsAmount[i] -=1;
                j += 1;
            }
        }

        game0.gameState = 3;

        // transfer flipped Pog 
        Cryptogs.safeBatchTransferFrom(address(this), game0.creator, flippedTogs, amountPlayer0, "");
        Cryptogs.safeBatchTransferFrom(address(this), game0.opponent, flippedTogs, amountPlayer1, "");

        emit FlipTogs(_gameId, game0.creator, game0.opponent, flippedTogs, amountPlayer0, amountPlayer1);
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