// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * This update RNG in https://github.com/austintgriffith/cryptogs/blob/master/Cryptogs/Cryptogs.sol to Chainlink VRF
 * 2 RNG cases (coin flip to determine the first mover, and randomly determine POG flipping) share the same callback function, which is a bit complicated. 
 * We can change it to multiple function if we want to.
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */
 
contract CryptogsVRF is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 1: Flip coin
     */
    function flipCoinVRF(bytes32 _stack, bytes32 _counterStack) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        //make sure it's the owner of the first stack (player one) doing the flip
        require(stacks[_stack].owner==msg.sender, "CryptogsRebooted: Wrong Owner of First Stack");
        //the counter must be a counter of stack 1
        require(stackCounter[_counterStack]==_stack, "CryptogsRebooted: Wrong Owner of Current Stack");
        require(counterOfStack[_stack]==_counterStack, "CryptogsRebooted: Wrong Owner of Counter Stack");
        //make sure that we are in mode 1
        require(mode[_stack]==1, "CryptogsRebooted: Wrong Game Mode for Coin Flipping");
        require(coinFlipRequested==false, "CryptogsRebooted: Wrong Game Mode for Coin Flipping");

        bytes32 requestId =  requestRandomness(keyHash, fee);
        //store the commit for the next tx
        stackOfRequestId[requestId]=stack;
        counterStackOfRequestId[requestId]=stack;

        return requestId;
    }

    /** 
     * Requests randomness 2: Slammer Time!
     */
    function SlammerVRF(bytes32 _stack, bytes32 _counterStack) public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
 
        if(lastActor[_stack]==stacks[_stack].owner){
            //it is player2's turn
            require(stacks[_counterStack].owner==msg.sender);
        }else{
            //it is player1's turn
            require(stacks[_stack].owner==msg.sender);
        }
        //the counter must be a counter of stack 1
        require(stackCounter[_counterStack]==_stack);
        require(counterOfStack[_stack]==_counterStack);
        //make sure that we are in mode 3
        require(mode[_stack]==2);

        //increase the mode to 3
        mode[_stack]=3;
        RaiseSlammer(_stack,_commit);

        //store the commit for the next tx
        bytes32 requestId =  requestRandomness(keyHash, fee);
        
        stackOfRequestId[requestId]=stack;
        counterStackOfRequestId[requestId]=stack;

        return requestId;
    }


    /**
     * Callback function used by VRF Coordinator
     * It does two things: 
     * 1. When used in flip coin, it determines the first mover.
     * 2. When used in flip POGs, it determines the whether a POG is flipped. 
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(coinFlipRequested == false){
            // coin not flipped, flip the coin
            _stack = stackOfRequestId[requestId];
            _counterStack = counterOfStack[_stack];

            if(uint256(randomness)%2==0){
            //player1 goes first
            lastBlock[_stack]=uint32(block.number);
            lastActor[_stack]=stacks[_counterStack].owner;
            CoinFlipSuccess(_stack,stacks[_stack].owner,true);
            }else{
            //player2 goes first
            lastBlock[_stack]=uint32(block.number);
            lastActor[_stack]=stacks[_stack].owner;
            CoinFlipSuccess(_stack,stacks[_counterStack].owner,false);
            }
            coinFlipRequested = true;
            mode[_stack]==2;
        }else{
            // flip the POGs
            // get stack by requested id
            _stack = stackOfRequestId[requestId];
            _counterStack = counterOfStack[_stack];

            if(lastActor[_stack]==stacks[_stack].owner){
                //player1 goes next
                lastBlock[_stack]=uint32(block.number);
                lastActor[_stack]=stacks[_counterStack].owner;
                }else{
                //player2 goes next
                lastBlock[_stack]=uint32(block.number);
                lastActor[_stack]=stacks[_stack].owner;
                }

                //look through the stack of remaining pogs and compare to byte to see if less than FLIPPINESS and transfer back to correct owner
                // oh man, that smells like reentrance --  I think the mode would actually break that right?
                bool done=true;
                uint8 randIndex = 0;
                for(uint8 i=0;i<10;i++){
                if(mixedStack[_stack][i]>0){
                    //there is still a pog here, check for flip
                    uint8 thisFlipper = uint8(pseudoRandomHash[randIndex++]);
                    //DebugFlip(pseudoRandomHash,i,randIndex,thisFlipper,FLIPPINESS);
                    if(thisFlipper<(FLIPPINESS+round[_stack]*FLIPPINESSROUNDBONUS)){
                    //ITS A FLIP!
                    uint256 tempId = mixedStack[_stack][i];
                    flipped[i]=tempId;
                    mixedStack[_stack][i]=0;
                    SlammerTime slammerTimeContract = SlammerTime(slammerTime);
                    //require( slammerTimeContract.transferBack(msg.sender,tempId) );
                    slammerTimeContract.transferBack(msg.sender,tempId);
                    }else{
                    done=false;
                    }
                }
                }

                throwSlammerEvent(_stack,msg.sender,previousLastActor,flipped);

                if(done){
                FinishGame(_stack);
                mode[_stack]=4;
                delete mixedStack[_stack];
                delete stacks[_stack];
                delete stackCounter[_counterStack];
                delete stacks[_counterStack];
                delete lastBlock[_stack];
                delete lastActor[_stack];
                delete counterOfStack[_stack];
                delete round[_stack];
                delete commitBlock[_stack];
                delete commit[_stack];
                }else{
                round[_stack]++;
                }

                return true;
            }
            }
            event ThrowSlammer(bytes32 indexed stack, address indexed whoDoneIt, address indexed otherPlayer, uint256 token1Flipped, uint256 token2Flipped, uint256 token3Flipped, uint256 token4Flipped, uint256 token5Flipped, uint256 token6Flipped, uint256 token7Flipped, uint256 token8Flipped, uint256 token9Flipped, uint256 token10Flipped);
            event FinishGame(bytes32 stack);

        }

        return true;

    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}
