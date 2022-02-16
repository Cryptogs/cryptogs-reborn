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
    mapping(address => uint256) private packsMintedByAddress;

    bool public whitelistOnly = true;
    mapping(address => bool) whitelist;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) private _vrfRequestIdToMinterAddress;

    constructor(address _vrfCoordinator, address _linkToken)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        ERC1155("https://game.example/api/item/{id}.json")
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18; // 0.0001 LINK
    }

    function whitelistMintPack() public whenNotPaused {
        require(whitelist[_msgSender()], "Address not whitelisted");
        _mintPack();
    }

    function publicMintPack() public whenNotPaused {
        require(!whitelistOnly, "Whitelist only");
        _mintPack();
    }

    function _mintPack() internal {
        require(numMinted + 5 <= maxTokenSupply, "Sold out");
        require(packsMintedByAddress[_msgSender()] < 1, "One pack per address");

        bytes32 requestId = _getRandomNumber();
        _vrfRequestIdToMinterAddress[requestId] = _msgSender();
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address minter = _vrfRequestIdToMinterAddress[requestId];
        uint256[] memory pogIds;
        uint256[] memory amounts;
        for (uint256 i = 0; i < 5; i++) {
            pogIds[i] =
                (uint256(keccak256(abi.encode(randomness, i))) % numPogTypes) +
                1;
            amounts[i] = 1;
        }
        _mintBatch(minter, pogIds, amounts, "");
    }

    function addToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function _getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }
}
