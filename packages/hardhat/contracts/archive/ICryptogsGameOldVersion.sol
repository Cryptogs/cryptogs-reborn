pragma solidity ^0.8.4;

/**
 * @author Steve P.
 * @notice ( A rework of the original Cryptogs contract by Austin Griffith)
 * Interface of the CryptogsGame contract where users can use erc1155 Cryptogs (v2) and play for keeps!
 * NOTE: this is an old version of the game, and it was realized after creating this. So we are going to archive this in case we want to work off of this game-play set up in the future. DO NOT INCLUDE IN DEPLOYED CONTRACTS
 */
interface ICryptogsGame {
    
    /* ========== EVENTS ========== */

    /**
     * @notice
     */
    event IPFS(string ipfs);

    /**
     * @notice
     */
    event Mint(bytes32 _image, address _owner, uint256 _id);

    /**
     * @notice
     */
    event MintPack(
        uint256 packId,
        uint256 price,
        uint256 token1,
        uint256 token2,
        uint256 token3,
        uint256 token4,
        uint256 token5,
        uint256 token6,
        uint256 token7,
        uint256 token8,
        uint256 token9,
        uint256 token10
    );

    /**
     * @notice
     */
    event SubmitStack(
        address indexed _sender,
        uint256 indexed timestamp,
        bytes32 indexed _stack,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        bool _external
    );

    /**
     * @notice
     */
    event BuyPack(address sender, uint256 packId, uint256 price);

    /**
     * @notice
     */
    event CounterStack(
        address indexed _sender,
        uint256 indexed timestamp,
        bytes32 indexed _stack,
        bytes32 _counterStack,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5
    );

    /**
     * @notice
     */
    event CancelStack(address indexed _sender, uint256 indexed timestamp, bytes32 indexed _stack);

    /**
     * @notice
     */
    event CancelCounterStack(
        address indexed _sender,
        uint256 indexed timestamp,
        bytes32 indexed _stack,
        bytes32 _counterstack
    );

    /**
     * @notice
     */
    event ThrowSlammer(
        bytes32 indexed stack,
        address indexed whoDoneIt,
        address indexed otherPlayer,
        uint256 token1Flipped,
        uint256 token2Flipped,
        uint256 token3Flipped,
        uint256 token4Flipped,
        uint256 token5Flipped,
        uint256 token6Flipped,
        uint256 token7Flipped,
        uint256 token8Flipped,
        uint256 token9Flipped,
        uint256 token10Flipped
    );

    /**
     * @notice
     */
    event FinishGame(bytes32 stack);

    /**
     * @notice
     */
    event DrainStack(bytes32 stack, bytes32 counterStack, address sender);

    /**
     * @notice
     */
    event StartCoinFlip(bytes32 stack, bytes32 commit);

    /**
     * @notice
     */
    event AcceptCounterStack(address indexed _sender, bytes32 indexed _stack, bytes32 indexed _counterStack);

    /**
     * @notice
     */
    event CoinFlipSuccess(bytes32 indexed stack, address whosTurn, bool heads);

    /**
     * @notice
     */
    event CoinFlipFail(bytes32 stack);

    /**
     * @notice
     */
    event RaiseSlammer(bytes32 stack, bytes32 commit);

    /**
     * @notice onlyOwner
     */
    function setIpfs(string _ipfs) external returns (bool);

    /**
     * @notice
     */
    function Cryptogs() external;

    /**
     * @notice
     */
    function setSlammerTime(address _slammerTime) external returns (bool);

    /**
     * @notice onlyOwner, and calls internal function _mint()
     */
    function mint(bytes32 _image, address _owner) external returns (uint256);

    /**
     * @notice onlyOwner
     */
    function mintBatch(
        bytes32 _image1,
        bytes32 _image2,
        bytes32 _image3,
        bytes32 _image4,
        bytes32 _image5,
        address _owner
    ) external returns (bool);

    /**
     * @notice onlyOwner
     */
    function mintPack(
        uint256 _price,
        bytes32 _image1,
        bytes32 _image2,
        bytes32 _image3,
        bytes32 _image4,
        bytes32 _image5,
        bytes32 _image6,
        bytes32 _image7,
        bytes32 _image8,
        bytes32 _image9,
        bytes32 _image10
    ) external returns (bool);

    /**
     * @notice
     */
    function buyPack(uint256 packId) external payable returns (bool);

    /**
     * @notice
     */
    function getToken(uint256 _id)
        external
        view
        returns (
            address owner,
            bytes32 image,
            uint256 copies
        );

    /**
     * @notice
     */
    function stackOwner(bytes32 _stack) external constant returns (address owner);

    /**
     * @notice
     */
    function getStack(bytes32 _stack)
        external
        constant
        returns (
            address owner,
            uint32 block,
            uint256 token1,
            uint256 token2,
            uint256 token3,
            uint256 token4,
            uint256 token5
        );

    //tx 1: of a game, player one approves the SlammerTime contract to take their tokens
    //this triggers an event to broadcast to other players that there is an open challenge
    /**
     * @notice
     */
    function submitStack(
        uint256 _id,
        uint256 _id2,
        uint256 _id3,
        uint256 _id4,
        uint256 _id5,
        bool _external
    ) external returns (bool);

    //tx 2: of a game, player two approves the SlammerTime contract to take their tokens
    //this triggers an event to broadcast to player one that this player wants to rumble

    /**
     * @notice emits CounterStack()
     */
    function submitCounterStack(
        bytes32 _stack,
        uint256 _id,
        uint256 _id2,
        uint256 _id3,
        uint256 _id4,
        uint256 _id5
    ) external returns (bool);

    // if someone creates a stack they should be able to clean it up
    // its not really that big of a deal because we will have a timeout
    // in the frontent, but still...

    /**
     * @notice emits CancelStack()
     */
    function cancelStack(bytes32 _stack) external returns (bool);

    /**
     * @notice
     */
    function cancelCounterStack(bytes32 _stack, bytes32 _counterstack) external returns (bool);

    //tx 3: of a game, player one approves counter stack and transfers everything in

    /**
     * @notice emits AcceptCounterStack()
     */
    function acceptCounterStack(bytes32 _stack, bytes32 _counterStack) external returns (bool);

    /**
     * @notice
     */
    function getMixedStack(bytes32 _stack)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    //tx 4: player one commits and flips coin up
    //at this point, the timeout goes into effect and if any transaction including
    //the coin flip don't come back in time, we need to allow the other party
    //to withdraw all tokens... this keeps either player from refusing to
    //reveal their commit. (every tx from here on out needs to update the lastBlock and lastActor)
    //and in the withdraw function you check currentblock-lastBlock > timeout = refund to lastActor
    //and by refund I mean let them withdraw if they want
    //we could even have a little timer on the front end that tells you how long your opponnet has
    //before they will forfet

    /**
     * @notice
     */
    function startCoinFlip(
        bytes32 _stack,
        bytes32 _counterStack,
        bytes32 _commit
    ) external returns (bool);

    //tx5: player one ends coin flip with reveal

    /**
     * @notice
     */
    function endCoinFlip(
        bytes32 _stack,
        bytes32 _counterStack,
        bytes32 _reveal
    ) external returns (bool);

    //tx6 next player raises slammer

    /**
     * @notice
     */
    function raiseSlammer(
        bytes32 _stack,
        bytes32 _counterStack,
        bytes32 _commit
    ) external returns (bool);

    //tx7 player throws slammer
    /**
     * @notice calls internal function throwSlammerEvent()
     */
    function throwSlammer(
        bytes32 _stack,
        bytes32 _counterStack,
        bytes32 _reveal
    ) external returns (bool);

    //this function is for the case of a timeout in the commit / reveal
    // if a player realizes they are going to lose, they can refuse to reveal
    // therefore we must have a timeout of TIMEOUTBLOCKS and if that time is reached
    // the other player can get in and drain the remaining tokens from the game
    /**
     * @notice
     */
    function drainStack(bytes32 _stack, bytes32 _counterStack) external returns (bool);

    /**
     * @notice
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice
     */
    function tokensOfOwner(address _owner) external view returns (uint256[]);

    /**
     * @notice
     */
    function withdraw(uint256 _amount) external returns (bool);

    /**
     * @notice
     */
    function withdrawToken(address _token, uint256 _amount) external returns (bool);

    //adapted from ERC-677 from my dude Steve Ellis - thanks man!
    /**
     * @notice calls private function contractFallback() + isContract()
     */
    function transferStackAndCall(
        address _to,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        bytes32 _data
    ) external returns (bool);
}
