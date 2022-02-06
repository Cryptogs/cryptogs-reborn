//TODO: Write up interface for slammer time - STEVE

pragma solidity ^0.8.4;

/**
 * @author Steve P.
 * @notice New interface of the original SlammerTime contract by Austin Griffith.
 * NOTE: This contract is for reference in case we need to look at how to incorporate it into the ETHDenver2022 Reboot contracts. It looks like SlammerTime.sol was part of v0 (7 tx version of the game), whereas the core functions of SlammerTime.sol were incorporated into the PizzaParlo.sol contract. 
 * This contract is for discussion purposes to outline the contract architecture used for EthDenver 2022.
 */

interface ICryptogsGame {

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    TODO: 
     */

    /**
     * @notice transfers tokens from player 1 and player 2 to this contract to act as an escrow
     NOTE: has to be called by cryptogs.sol
     * TODO: Old contracts required only cryptogs.sol called the startSlammerTime() function. NOTE: SlammerTime.sol looks like it is not used with Pizza Parlor, so it is part of v0 I believe. 
     If we end up using stuff from Slammer time, the requirement for the cryptogs file to be the msg.sender needs to be revisited since we are abstracted parts away from the Cryptogs file in some way. Once the architecture of the contracts is determined for how we will keep extensibility / modularity, make sure to implement the appropriate changes here too. 
     */
    function startSlammerTime(address _player1,uint256[5] calldata _id1,address _player2, uint256[5] memory _id2) external returns (bool);


    /**
     * @notice transfers tokens back to players, has to be called by cryptogs.sol
     */
    function transferBack(address _toWhom, uint256 _id) external returns (bool);
    
}
