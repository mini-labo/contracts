// SPDX-License-Identifier: GPL-3.0

/// @title MINI ERC-721 token

pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IMiniDataRepository.sol";
import "./interfaces/IMiniToken.sol";

contract MiniToken is IMiniToken, Ownable, ERC721 {
    IMiniDataRepository dataRepository;

    address private auctionHouseAddress;

    uint256 public tokenCounter;

    constructor(address _dataRepository) ERC721("Mini", "MINI") {
        dataRepository = IMiniDataRepository(_dataRepository);
    }

    function mintTokenTo(address to) public {
        require(msg.sender == auctionHouseAddress, "invalid sender");
        _mint(to, tokenCounter);
        emit TokenCreated(tokenCounter);

        tokenCounter = tokenCounter += 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'URI query for nonexistent token');
        return dataRepository.tokenData(_tokenId);
    }

    function nextTokenId() external view returns (uint256) {
        return tokenCounter + 1;
    }

    function setAuctionHouse(address _auctionHouse) external onlyOwner {
         auctionHouseAddress = _auctionHouse;
    }
}
