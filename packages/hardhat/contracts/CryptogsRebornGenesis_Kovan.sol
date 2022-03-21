// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CryptogsRebornGenesis is VRFConsumerBase, ERC1155, Ownable, Pausable {
    uint256 public numPogTypes = 73;
    uint256 public numMinted;
    uint256 public maxTokenSupply = 18375;
    mapping(address => uint256) private packsMintedByAddress;

    bool public whitelistOnly = true;
    mapping(address => bool) whitelist;

    event mintPog(
    address indexed sender,
    bytes32 indexed requestId
    );

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(bytes32 => address) private _vrfRequestIdToMinterAddress;

    constructor(address _vrfCoordinator, address _linkToken)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        ERC1155("https://cryptogs-genesis-metadata.vercel.app/api/{id}")
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.0001 LINK
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
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        // get random number
        bytes32 requestId = requestRandomness(keyHash, fee);
        _vrfRequestIdToMinterAddress[requestId] = _msgSender();
        numMinted = numMinted + 5;
        emit mintPog(_msgSender(), requestId);
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
                (uint256(keccak256(abi.encode(randomness, i))) % numPogTypes);
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

    function setURI(string memory _newuri) external onlyOwner {
        _setURI(_newuri);
    }
}
