// SPDX-License-Identifier: GPL-3.0

// @title interface for Mini Auctions

pragma solidity ^0.8.10;

interface IMiniAuctionHouse {
    struct Auction {
        // ID for the data mapping in the MiniDataRepository.
        // This will become the ERC721 token ID after mint.
        uint256 miniId;
        // current winning bid
        uint256 amount;
        // time that the auction started
        uint256 startTime;
        // scheduled end time for auction
        uint256 endTime;
        // address of the current winning bidder
        address payable bidder;
        // flag that will resolve to true after auction has settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed miniId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed miniId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed miniId, uint256 endTime);

    event AuctionSettled(uint256 indexed miniId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 miniId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}
