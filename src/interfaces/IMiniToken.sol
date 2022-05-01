// SPDX-License-Identifier: GPL-3.0

// @title Mini Token

pragma solidity ^0.8.10;

interface IMiniToken {
    function mintTokenTo(address to) external;

    function nextTokenId() external view returns (uint256);

    function tokenCounter() external view returns (uint256);

    event TokenCreated(uint256 indexed tokenId);
}
