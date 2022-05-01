// SPDX-License-Identifier: GPL-3.0

/// @title MINI Data Repository

pragma solidity ^0.8.10;

interface IMiniDataRepository {
    // retrieve a token's saved metadata as bytes
    function tokenMetadata(uint256 _id) external view returns (bytes memory);
    // set an artist for a dataset
    function setArtist(uint256 _id, address _address) external;
    // get an artist for a dataset
    function artistFor(uint256 _id) external view returns (address);
}
