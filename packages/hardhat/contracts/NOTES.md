# Notes

This is a breakdown of the smart contracts that make up CRYPTOGS. Please note that this is a WIP and there are unfinished sections for now.

Section 1 is focused on the MVP that will be launched for EthDenver with POAPathon. It is important to outline the core functions and the general architecture to ensure agreement across the team. They are actually outlined in the interface and a separate notion doc at the moment (see link below). This README.md will be updated later on.

> NOTE: for the start of the smart contracts for EthDenver 2022, we are referencing PizzaParlor.sol, the upgraded smart contract that includes the gameplay (including slammer logic) in it. The original version, aka OG Cryptogs, was deployed with SlammerTime and Cryptogs contracts which consisted of 7 txs.

Section 2 covers the history of Cryptogs in terms of smart contract functionality and walks through the functions within both versions found within the original repo. The earliest version had 7 transactions for game-play, whereas the next revision had only 3 transactions. If you would like to see the breakdown for the 7 txs please see the toggle at the bottom of this file. Please note that it is roughly written but covers the majority of the original game-play sequences.

---

# Section 1: EthDenver MVP

## High-Level Blurb Explaining the Mechanics:

See interface file ICryptogsGamePizzaParlorVersion.sol.

- Team to discuss architecture there and through github issue conversations.

## Scope of MVP:

TODO: migrate these notion docs to a markdown file within this repo.

https://healthy-circle-c04.notion.site/General-Scope-of-Work-f08da9d16eaa4991b1aabfba81e8e63f

---

## Ideas for EthDenver

### Minting

- If we are using erc1155s now, then we have numerous varieties of Crytogs, with their own general ID. That general ID correlates with its index in the library of different types of Cryptogs available. The key difference between using erc721s and erc1155s in terms of unique ownership is that a user does not own a specific ID of a respective NFT collection. They instead own one token of many of the same tokens of a collection.

Example.) So if Bob and Allice both owned Cryptog Bellsprout, then they would not have unique IDs for their NFTs. Imagine Vitalik, Satoshi, and Andre Cronje came along and had Cryptog Charizards, those would have a different index ID, but again none of them would have unique IDs for each respective Charizard. Contrary to belief, all Charizards are equal.

### Gameplay

As seen in `PizzaParlor.sol`, the later version of the Cryptogs contracts, three txs are only needed for gameplay. This seems like a reasonable way of carrying out the MVP. Gas for the generateGame() transaction will be randomly decided between the two players. Perhaps we can implement something where if they had played once already then they rotate who pays gas next from there on out.

#### Ideas for SlammerTime

- Incorporate a function that whitelists the game contract or vice versa. Have to think about the architecture. Note that the OG contracts instantiated the contracts, essentially the version of importing contracts back then I think.
- Can we create private functions or roll the functions of raise and throw slammer into one function? Why do they need to be separate?
- Also think we can deploy CoinFlip into another contract just to reduce the length of this thing. --> it would implement the commit/reveal aspects of the code.

### Future Ideas:

- Add a way to directly challenge a specific user, or if a challenge is open, have a way to specify the single user so no one else can just spam you with challenges --> a bit of front end and smart contract work to showcase the right address as the challenger.

---

### Aspects that Need Clarification

Just need to look at the math more closely and decide if we need to tweak this.

- FLIPPINESS:

- BONUS:

---

## Non-Smart Contract Work and Coordination

This section just outlines topics and/or TODOs for our team to coordinate with the other development teams. See issues for discussion points off of these aspects.

TODO: if reusing code: we need to know if the server side stuff in the repo? Does it work? It won't work with erc1155 or erc721.
---> therefore not able to start a game with the front end... the way we want.

TODO: This raises the question for TylerS to see if he really wants to work on this for a long time to check stuff with the pre-existing repo. \*Note Deepe can try to look for this stuff Saturday, but discuss accordingly.

TODO: Assign someone to write tests for the non-smart contracts side of things.

---

# Section 2: Cryptogs History

This section outlines some key parts of the original smart contracts and gameplay.

## 1.0 OG Release

- A breakdown of the scope of the project tldr;

TODO: SlammerTime.sol and Cryptogs.sol were the core contracts. See the "inspo/OG file" within the contracts subdirectory. The OG project was created during an EthDenver hackathon by Austin Griffith and his team, and this "reborn" Cryptogs project has been relaunched for EthDenver 2022!

---

## Cryptogs Game - OG Contracts (7 transaction game-play)]

### Austin's original information about the project (2018):

[<img src="https://cryptogs.io/screen.jpg">](https://cryptogs.io)

We extended the ERC-721 token standard to include the game of pogs!

All interactions happen on-chain including a commit/reveal scheme for randomness.

Purchase a pack of pogs for basically the gas it cost to mint them and come play with the rest of the decentralized world.

[It's SLAMMER TIME on the blockchain!](https://cryptogs.io)

[<img src="https://cryptogs.io/screens/slam.gif">](https://cryptogs.io)

<details markdown='1'><summary>Contract Breakdown</summary>

### Minting:

TODO: this still needs to be confirmed as I didn't spend too much time combing it since we're 4 years later from when this contract was written, and we have newer minting schemes now.

OG contracts minted them in the same contract as the game, in packs. There are two public functions, both onlyOwner, that can be used to mint packs: mintPack() and mintBatch(). These tokens are minted, where they are given an ID aligning with Item[] items. So each element within the Item[] array contains a unique erc721 with its data stored in a struct Item. The only thing stored in the Item struct seems to be bytes32 image. Rarity is kept track of through mapping(bytes32 => uint256) public tokensOfImage, where bytes32 represents the image of the respective erc721.

- mintBatch() looks like it is only used when the owner of the contract is gifting or airdropping batches to folks.

GAMEPLAY:

- Two users present their stack of Cryptogs for game. They were dealing with erc721s (in a less standardized way it seems). erc721s were

First tx:

- First user preps their stack and presents it, calling the function submitStack(). This function approves the SlammerTime contract to take these tokens. Event triggered is broadcast to players showing an open challenge.
  - require(owner[token]=msg.sender);
  - require(approve(slammerTime(<correctToken>)))
  - Generate stack (hash of nonce of this contract? and msg.sender address)
  - Creates a Stack struct with the Cryptogs chosen (stored in memory as an array), with the block.number of the tx.
  - Stores the Stack struct into stacks mapping which is a (bytes32 => Struct) mapping.
  - SubmitStack() is the event that is broadcast for challengers containing: msg.sender, time of challenge (now), bytes32 stack, cryptogs ids, and whether the game is public or private)

Second tx:

- Player approves SlammerTime contract to take their tokens.
- Triggers an event broadcasted to player one of player 2's intent to rumble!
- TODO: not sure what `_id` is
- Creates a Stack struct just like tx1 but for player2.
- Populates stackCounter mapping(bytes32 => bytes32) with the bytes32 \_stack from player 1. This stores the actual game players and the nonces that they were each accepted.

TODO: there is a comment about cleaning up their stack if the user created their stack... not sure what this means and is referring to. The comment went on to say that the timeout in the frontend will help solve this but it is still something to be solved.

Optional txs:

cancelStack(bytes32 \_stack)

- requires that mode[_stack] == 0; TODO: not sure what mode is, but I think it is a boolean representing the state of the game. If it is 0 than it has not started (accepted by player1)
- Make sure that it is not a counterStack[], I guess if it is... then that's just the counterStack backing out of the game, player 1 should not have to redeploy the initial challenge.
- deletes the mapping stacks[_stack] so it is no longer an open challenge.

cancelCounterStack()

- deletes stacks[_counterstack], which is the record of counterStack struct
- deletes stackCounter[_counterstack], which is record of the challenge to player 1.

GAME ON: Third tx

acceptCounterStack()

- Checks that the hexStrings align the proper players and stack details.
- Calls on slammerTime to `startSlammerTime()` with parameters of the game (player 1, player 1 struct cryptog ids, player 2 according to counterStack mapping, player 2 cryptogs ids according to counterStack mapping )
- TODO: what is up with the block.number for timeout? and lastActor[_stack]
- TODO: why is counterOfStack[_stack] needed? --> looks like it comes up in coin flip later.
- Populates mixedStack mapping of hash pointing to uint256 representing in-game id of cryptog. TODO: pay close attention to the ids here. Also not sure if all the implementation code they wrote is the most efficient lol.
- emits AcceptCounterStack for front end to notify user of starting the game.

getMixedStack() is just a view function.

- NOTE: stacks(bytes => Stack) are only for player 1s!

Fourth tx:

starCoinFlip():

- TODO: where does \_commit (bytes32) come from??
- TODO: it seems that there are a lot of requires here, more than needed but need to check.
- commitBlock(bytes=>uint32) is a typecast of uint32 on the block.number
- increment to mode 2.
- TODO: Outline and think out the timeout necessary, and thus how to use commitBlock, timeout, lastBlock, lastActor. --> see comment in OG contracts. I think that we ensure that lastBlock is updated and lastActor is updated to ensure that we are moving with the blockchain in terms of on-chain txs that record the game details.

Fifth tx:

endCoinFlip()

- TODO: where does bytes32 \_reveal come from?
- block stuff: makes sure that uint32(block.number) > commitBlock[_stack] --> OK this is just to ensure that we're ahead in the blockchain I think.
  **- This is where the whole commit/reveal sequence starts to show. TODO: research this.**
- Let's go down the successful coin flip route;
- increment mode, increment round[_stack]
- I think this is the reveal/commit key:
  `bytes32 pseudoRandomHash = keccak256(_reveal, block.blockhash(commitBlock[_stack]));`
- decides who goes first in raiseSlammer().

Sixth tx:

raiseSlammer()

- checks who's turn it is.
- makes sure we're in mode 3
- assigns commit to \_commit.
- rewrites commitBlock[_stack]

7th tx:
throwSlammer()

- check who's turn it is.
- change mode to 4
- make sure we're in the next block past commitBlock
- instantiate local var uint256[10] memory flipped that will keep track of which token is flipped in mixedStack
- if reveal/commit don't match up then we're going to be returned to slammer raise. Front end needs to line up with this.
- if successful reveal/commit, then we finally play and check what flipped in this round!
- We also assign the lastActor and lastBlock variables so the other player will be able to raise and throw slammer after this turn if there are remaining Cryptogs.
- implements the conditional logic to assess if a flip occurs or not. If a flip does occur, then slammerTime function transferBack() is called and the respective Cryptogs are sent to the msg.sender!

---

### SlammerTime

startSlammerTime():

- only the game contract can call this function.
- instantiates the game contract locally in the function to access its methods.
- approvals of transfers have been already made by game contract and users for SlammerTime to take the tokens as escrow. SlammerTime carries out the transfer of all tokens in that game using 2 for-loops.
- returns boolean signifying transfer complete.

transferBack():

- Activated during several parts of gameplay where the cryptogs are sent back to the proper owners depending on gameplay results.

 </details>

---
