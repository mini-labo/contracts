// SPDX-License-Identifier: GPL-3.0

/// @title MINI Data Repository

pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "sstore2/SSTORE2.sol";
import "base64/base64.sol";

import "./interfaces/IMiniDataRepository.sol";
import "./interfaces/IMiniToken.sol";

// repository for MINI token metadata
contract MiniDataRepository is IMiniDataRepository, Ownable {
    address public miniTokenAddress;

    // The curators are addresses whitelisted to add data to the repository.
    mapping(address => bool) curatorAddresses;

    // mapping of token ID to address pointers of addresses containing metadata bytes
    mapping(uint256 => address) public tokenDataAddresses;

    // mapping of token ID to artist address
    mapping(uint256 => address) public artistFor;

    // id of next dataset to be inserted into repository
    uint256 private nextDataId;
    
    constructor() {
        curatorAddresses[msg.sender] = true;
    }

    // add token metadata to be stored on chain.
    // metadata should be constructed off-chain to be in the appropriate format.
    // formatTokenData can be called to construct an appropriate parameter for this function from string data
    function addData(bytes memory _encodedMetadata) external onlyCurator {
        require(_encodedMetadata.length < 4000, "metadata must be less than 4000 bytes");

        address dataAddress = SSTORE2.write(_encodedMetadata);
        tokenDataAddresses[nextDataId] = dataAddress;
        emit TokenDataAdded(nextDataId);

        nextDataId = nextDataId += 1;
    }

    // set the address of artist to be credited for a specific data set. This enables revenue sharing for the artist on auction sales.
    function setArtist(uint256 _id, address _artist) external onlyCurator {
        artistFor[_id] = _artist;

        emit ArtistForDataUpdated(_id, _artist);
    }

    // edit a data entry.
    // This is an emergency method intended for curators to repair any malformed data that is uploaded.
    // This will not be possible to invoke once data has been associated with a token or auction.
    function editData(uint256 _id, bytes calldata _encodedMetadata) external onlyCurator {
        // token data can not be edited if the corresponding tokenId has been minted, or is being auctioned (next to be minted)
        require(_id > IMiniToken(miniTokenAddress).nextTokenId(), "data can no longer be edited");
        require(_encodedMetadata.length < 4000, "metadata must be less than 4000 bytes");

        address newDataAddress = SSTORE2.write(_encodedMetadata);
        tokenDataAddresses[_id] = newDataAddress;

        emit TokenDataEdited(_id);
    }

    // retreive metadata bytes from storage contract address
    function tokenMetadata(uint256 _id) external view returns (bytes memory) {
        return SSTORE2.read(tokenDataAddresses[_id]);
    }

    // formats token information into metadata bytes
    // this is externally callable and intended to be used as a helper call to construct the appropriate bytes
    // to be used with an addData transaction
    function formatTokenData(
      string calldata _name,
      string calldata _description,
      string calldata _artistName,
      string calldata _generation,
      string calldata _imageData
    ) public pure returns (bytes memory) {
        string memory baseUrl = "data:application/json;base64,";
        return abi.encodePacked(
            baseUrl,
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', _name, '",',
                '"description":"', _description, '",', 
                '"attributes":[{"trait_type":"artist","value":"', _artistName, '"},{"display_type":"number","trait_type":"generation","value":', _generation, '}],'
                '"image":"', _imageData, '"}'
            )))
        );
    }

    function setMiniTokenAddress(address _miniToken) external onlyOwner {
        miniTokenAddress = _miniToken;
    }

    function addCurator(address _newCurator) external onlyOwner {
        curatorAddresses[_newCurator] = true;

        emit CuratorAdded(_newCurator);
    }

    function removeCurator(address _curatorToBeRemoved) external onlyOwner {
        curatorAddresses[_curatorToBeRemoved] = false;

        emit CuratorRemoved(_curatorToBeRemoved);
    }

    function isCurator(address _address) public view returns (bool) {
        return curatorAddresses[_address];
    }

    modifier onlyCurator {
        require(curatorAddresses[msg.sender] == true, "only curators can perform this action");
        _;
    }
}
