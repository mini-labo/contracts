// SPDX-License-Identifier: GPL-3.0

/// @title MINI Data Repository

pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "sstore2/SSTORE2.sol";
import "base64/base64.sol";

import "./interfaces/IMiniDataRepository.sol";

// repository for MINI token metadata
contract MiniDataRepository is IMiniDataRepository, Ownable {
    address public miniTokenContract;

    // The curators are addresses whitelisted to add data to the repository.
    mapping(address => bool) curatorAddresses;

    // mapping of token ID to address pointers
    mapping(uint256 => address) public tokenDataAddresses;

    // id of next dataset to be inserted into repository
    uint256 private nextDataId;
    
    // id of the next token to be minted
    uint256 private nextTokenId;

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
        nextDataId = nextDataId += 1;
    }

    // edit a data entry.
    // This is an emergency method intended for curators to repair any malformed data that is uploaded.
    // This will not be possible to invoke once data has been associated with a token or auction.
    function editData(uint256 _id, bytes memory _encodedMetadata) external onlyCurator {
        // token has not been minted, and is not being auctioned (next to be minted)
        require(_id > nextTokenId, "data can no longer be edited");
        require(_encodedMetadata.length < 4000, "metadata must be less than 4000 bytes");

        address newDataAddress = SSTORE2.write(_encodedMetadata);
        tokenDataAddresses[_id] = newDataAddress;
    }

    // retreive metadata bytes from storage contract address
    function tokenMetadata(uint256 _id) external view returns (bytes memory) {
        return SSTORE2.read(tokenDataAddresses[_id]);
    }

    // formats token information into metadata bytes
    function formatTokenData(
      string memory _name,
      string memory _description,
      string memory _attributes,
      string memory _imageData
    ) public pure returns (bytes memory) {
        string memory baseUrl = "data:application/json;base64,";
        return abi.encodePacked(
            baseUrl,
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', _name, '",',
                '"description":"', _description, '",', 
                '"attributes":', _attributes, ',',
                '"image":"', _imageData, '"}'
            )))
        );
    }

    function incrementNextTokenId() external {
        require(msg.sender == miniTokenContract, "invalid sender");
        nextTokenId = nextTokenId += 1; 
    }

    function setMiniTokenAddress(address _miniToken) external onlyOwner {
        miniTokenContract = _miniToken;
    }

    function addCurator(address _newCurator) external onlyOwner {
        curatorAddresses[_newCurator] = true;
    }

    function removeCurator(address _curatorToBeRemoved) external onlyOwner {
        curatorAddresses[_curatorToBeRemoved] = false;
    }

    function isCurator(address _address) public view returns (bool) {
        return curatorAddresses[_address];
    }

    modifier onlyCurator {
        require(curatorAddresses[msg.sender] == true, "only curators can perform this action");
        _;
    }
}
