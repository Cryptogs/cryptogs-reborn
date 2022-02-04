// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
  -- Arthur Silveira for the Cryptogs Reborn game
  ( A rework of the original Cryptogs contract by Austin Griffith)
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptogsReborn is ERC1155, Ownable {

    uint256 public numTokenTypes = 20;
    mapping (uint256 => uint256) public numMintedByTokenType;

    uint256 public maxTokenSupply = 250;

  constructor() ERC1155("https://game.example/api/item/{id}.json") {}

  function publicMint(uint amount, uint pogType) public payable {
      require(pogType < numTokenTypes, 'No pog of this type exists');
      require(numMintedByTokenType[pogType] + amount <= maxTokenSupply, 'Not enough pogs of this type');
      _mint(msg.sender, pogType, amount, "");
      numMintedByTokenType[pogType] += amount;
  }
}