// SPDX-License-Identifier: GPL-3.0

/// @title MINI ERC-721 token

pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "base64/base64.sol";

import "./interfaces/IMiniDataRepository.sol";
import "./interfaces/IMiniToken.sol";

contract MiniToken is IMiniToken, ERC721Enumerable {
    IMiniDataRepository dataRepository;

    uint256 public tokenCounter;

    constructor(address _dataRepository) ERC721("Mini", "MINI") {
        dataRepository = IMiniDataRepository(_dataRepository);       
    }

    // TODO: access restriction (post auction mechanism)
    function mintToken() public {
        _safeMint(msg.sender, tokenCounter);
        emit TokenCreated(tokenCounter);

        tokenCounter = tokenCounter += 1;
        dataRepository.incrementNextTokenId();
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(dataRepository.tokenMetadata(_tokenId));
    }

    function nextTokenId() external view returns (uint256) {
        return tokenCounter + 1;
    }
}
