// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// @author cosmoburn.eth, deepe.eth
contract CryptogsRebornGenesis is VRFConsumerBase, ERC1155, Ownable, Pausable {
  uint256 public numPogTypes = 73;
  uint256 public numMinted;
  uint256 public maxTokenSupply = 3675;
  bool public whitelistOnly = true;

  mapping (address => bool) whitelist;

  // Chainlink VRF
  bytes32 internal keyHash;
  uint256 internal fee;
  mapping(bytes32 => address) private _vrfRequestIdToMinterAddress;

  constructor(address _vrfCoordinator, address _linkToken)
    VRFConsumerBase(_vrfCoordinator, _linkToken)
    ERC1155("https://game.example/api/item/{id}.json")
  {
    // TODO: don't hardcode this stuff
    keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
  }

  function whitelistMintPack() public whenNotPaused {
    require(whitelist[_msgSender()], "Address not whitelisted");
    _mintPack();
  }

  function publicMintPack() public whenNotPaused {
    require(!whitelistOnly, "");
    _mintPack();
  }

  function _mintPack() internal {
    require(numMinted + 5 <= maxTokenSupply, "Sold out");

    bytes32 requestId = _getRandomNumber();
    _vrfRequestIdToMinterAddress[requestId] = _msgSender();
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    address minter = _vrfRequestIdToMinterAddress[requestId];
    uint256[] memory pogIds;
    uint256[] memory amounts;
    for (uint i = 0; i < 5; i++) {
      pogIds[i] = uint256(keccak256(abi.encode(randomness, i))) / 255 * numPogTypes;
      amounts[i] = 1;
    }
    _mintBatch(minter, pogIds, amounts, "");
  }

  function addToWhitelist(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  function removeFromWhitelist(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = false;
    }
  }

  function _getRandomNumber() private returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    return requestRandomness(keyHash, fee);
  }
}