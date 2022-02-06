pragma solidity ^0.8.4;

/**
 * @author Steve P.
 * @notice ( A rework of the original Cryptogs (PizzaParlor) contract by Austin Griffith)
 *
 *   PizzaParlor -- a new venue for cryptogs games
     less transactions than original Cryptogs.sol assuming some
     centralization and a single commit reveal for randomness
 *
 * Interface of the CryptogsGame contract where users can use erc1155 Cryptogs (v2) and play for keeps! 
 * TODO: Use this interface file for discussing key components of contract architecture.
 * NOTE: off-chain will need a small backend to handle the beginner off-chain stuff.
 */
interface ICryptogsGame {

    /* ========== EVENTS ========== */

    // TODO: write these up at the end when we know what functions we're using. Make sure to coordinate with front-end.

    /**
     * @notice emitted when transferStack() executed
     */
    event TransferStack(
        bytes32 indexed _commit,
        address indexed _sender,
        bytes32 indexed _receipt,
        uint256 _timestamp,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5
    );

    /**
     * @notice
     */
    event CoinFlip(bytes32 indexed _commit, bool _result, address _winner);

    /**
     * @notice
     */
    event GenerateGame(bytes32 indexed _commit, address indexed _sender);

    /**
     * @notice
     */
    event Flip(bytes32 indexed _commit, uint8 _round, address indexed _flipper, uint256 indexed _token);

    /**
     * @notice
     */
    event DrainGame(bytes32 indexed _commit, address indexed _sender);

    /**
     * @notice
     */
    event RevokeStack(
        bytes32 indexed _commit,
        address indexed _sender,
        uint256 _timestamp,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        bytes32 _receipt
    );

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    TODO: Assess the RNG method we will use: Chainlink VRF vs Commit/Reveal. 
    TODO: Assess specifically if the RNG method will work with the for-loop mechanism or however else we go about setting up the flip game-logic
    TODO: Assess implementation of erc1155s, and how we will incorporate new whitelisted Cryptogs to the game.
    TODO: Assess deployment plan and process for onchain
    TODO: Write in proper comments for functions
    TODO: Finalize architectural design
     */
    /* ========== OFF-CHAIN GAMEPLAY FUNCTIONS ========== */

    // to make less transactions on-chain, game creation will happen off-chain
    // at this point, two players have agreed upon the ten cryptogs that will
    // be in the game, five from each player
    // the server will generate a secret, reveal, and commit
    // this commit is used as the game id and both players share it
    // the server will pick one user at random to be the game master
    // this player will get the reveal and be in charge of generating the game
    // technically either player can generate the game with the reveal
    // (and either player can drain the stack with the secret)

    //tx1&2: players submit to a particular commit hash their stack of pogs (the two txs can happen on the same block, no one is waiting)
    //these go to the Cryptogs contract and it is transferStackAndCall'ed to here
    // event TransferStack emitted

    /**
     * @notice called by each player, individually, and records commitReceipt, stacksTransferred records for the player, while ensuring transfer of ownership of token to PizzaParlor.sol 
     */
    function onTransferStack(
        address _sender,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        bytes32 _commit
    ) external;

    //tx3: either player, knowing the reveal, can generate the game
    //this tx calculates random, generates game events, and transfers
    // tokens back to winners
    //in order to make game costs fair, the frontend should randomly select
    // one of the two players and give them the reveal to generate the game
    // in a bit you could give it to the other player too .... then after the
    // timeout, they would get the secret to drain the stack
    //* TODO: Assess how we're going to handle who gets the gas transaction to start the game and how we'll make it fair (if it even matters since we're on MATIC)

    /**
     * @notice runs checks to ensure game to be generated is following rules. Calls internal function _generateGame() to carry out gameplay. 
     * NOTE: internal function _flip() is where the transferrance of the tokens are made if the Cryptogs are flipped during that player's turn, respectively.
     */
    function generateGame(
        bytes32 _commit,
        bytes32 _reveal,
        address _opponent,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        uint256 _token6,
        uint256 _token7,
        uint256 _token8,
        uint256 _token9,
        uint256 _token10
    ) external;

    //if the game times out without either player generating the game,
    // (the frontend should have selected one of the players randomly to generate the game)
    //the frontend should give the other player the secret to drain the game
    // secret -> reveal -> commit

    /**
     * @notice when time runs out during beginning of the game, the player not elected to start the game can call this. It calls internal function _drainGame() which sends all of the in-play Cryptogs (escrowed) to themselves. TODO: We need to sort out whether or not sending them all to one player is the right move, I guess it is an incentive to not just join any game willy nilly.
     */
    function drainGame(
        bytes32 _commit,
        bytes32 _secret,
        address _opponent,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5,
        uint256 _token6,
        uint256 _token7,
        uint256 _token8,
        uint256 _token9,
        uint256 _token10
    ) external;

    //if only one player ever ends up submitting a stack, they need to be able
    //to pull their tokens back

    /**
     * @notice option for player if they submit a stack to the escrow contract but the other player does not. Allows player to retrieve their cryptogs from escrow and deletes the record of the transfer (commitReceipt hash).
     */
    function revokeStack(
        bytes32 _commit,
        uint256 _token1,
        uint256 _token2,
        uint256 _token3,
        uint256 _token4,
        uint256 _token5
    ) external;
}
