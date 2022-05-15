// SPDX-License-Identifier: GPL-3.0

/// @title MINI Data Repository

pragma solidity ^0.8.10;

interface IMiniDataRepository {
    // retrieve a token's saved metadata
    function tokenData(uint256 _id) external view returns (string memory);
    // set an artist for a dataset
    function setArtist(uint256 _id, address _address) external;
    // get an artist for a dataset
    function artistFor(uint256 _id) external view returns (address);

    event TokenDataAdded(uint256 indexed id);

    event TokenDataEdited(uint256 indexed id);

    event ArtistForDataUpdated(uint256 indexed id, address artist);

    event CuratorAdded(address _curator);

    event CuratorRemoved(address _curator);
}
