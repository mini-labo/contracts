// SPDX-License-Identifier: GPL-3.0

/// @title MINI ERC-721 token

pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "sstore2/SSTORE2.sol";
import "base64/base64.sol";
import "forge-std/console.sol";

contract Mini is ERC721Enumerable {
    uint256 public tokenCounter;

    // mapping of token ID to address pointers
    mapping(uint256 => address) public tokenDataAddresses;

    constructor() ERC721("Mini", "MINI") {}

    event TokenCreated(uint256 indexed tokenId, address tokenDataAddress);

    function mintToken(string memory _encodedImageData) public {
        bytes memory bytesImage = bytes(_encodedImageData);
        require(bytesImage.length < 900, "image must be less than 900 bytes");
        _safeMint(msg.sender, tokenCounter);

        bytes memory tokenData = formatTokenData(bytesImage);
        address dataAddress = SSTORE2.write(tokenData);
        tokenDataAddresses[tokenCounter] = dataAddress;

        emit TokenCreated(tokenCounter, dataAddress);
        tokenCounter = tokenCounter += 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(SSTORE2.read(tokenDataAddresses[tokenId]));
    }

    function formatTokenData(bytes memory tokenData) public pure returns (bytes memory) {
        string memory baseUrl = "data:application/json;base64,";
        return abi.encodePacked(
            baseUrl,
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"MINI', '###', '",',
                '"description":"test token from MINI",', 
                '"attributes":"",',
                '"image":"', tokenData, '"}'
            )))
        );
    }
}
