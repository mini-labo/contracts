// SPDX-License-Identifier: GPL-3.0

/// @title Mini Auction House

// LICENSE
// A modified version of NounsAuctionHouse.sol from Nouns DAO,
// which itself is a modified version of Zora's AuctionHouse.sol.
// used with humility and respect under the terms of GPL-3.0 license :)

pragma solidity ^0.8.10;

import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IMiniAuctionHouse.sol";
import "./interfaces/IMiniToken.sol";
import "./interfaces/IWETH.sol";

contract MiniAuctionHouse is IMiniAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    IMiniToken public miniToken;

    // Address of the WETH contract
    address public weth;

    // the minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // minimum price accepted for an auction
    uint256 public reservePrice;

    // minimum percentage difference that bids can be incremented by
    uint8 public minBidIncrementPercentage;

    // duration of a single auction
    uint256 public duration;

    // currently active auction
    IMiniAuctionHouse.Auction public auction;

    /**
      * @notice initialize the auction house and base contracts
      * start with the auction house initially paused.
      * @dev This function can only be called once
      */ 
    function initialize(
        address _mini, 
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        miniToken = IMiniToken(_mini);
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    // settle the current auction mint the token for the winner, and trigger the next auction
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    // settle auction only, without creating a new auction. For use when auction processing is paused
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    function createBid(uint256 _miniId) external payable override nonReentrant {
        IMiniAuctionHouse.Auction memory _auction = auction;

        require(_auction.miniId == _miniId, "provided id not currently being auctioned");
        require(block.timestamp < _auction.endTime, "auction has ended");
        require(msg.value >= reservePrice, "must bid above reservePrice");
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must bid minBidIncrementPercentage more than the previous bid"
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // extend the auction if bid received within timeBuffer and endTime
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
            emit AuctionExtended(_auction.miniId, _auction.endTime);
        }

        emit AuctionBid(_auction.miniId, msg.sender, msg.value, extended);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    // unpause a paused auction house. this will create a new auction if necesssary.
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    // Create an auction
    // Auction details are stored in state. The mini to be auctioned is fetched from the data repository entry
    // corresponding to the next ID to be minted.
    function _createAuction() internal {
        uint256 miniId = miniToken.nextTokenId() - 1; // index starting at 0
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auction = Auction({
            miniId: miniId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(miniId, startTime, endTime);
    }

    function _settleAuction() internal {
        IMiniAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "auction has not begun");
        require(!_auction.settled, "auction has already been settled");
        require(block.timestamp >= _auction.endTime, "auction is ongoing");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            // no bids
            // restart auction with same token. TODO: add override
            _createAuction();
        } else {
            // mint to winner
            miniToken.mintTokenTo(_auction.bidder);
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.miniId, _auction.bidder, _auction.amount);
    }

    // transfer ETH - falling back to WETH on failure
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    // transfer ETH and return success status
    // only forwards 30,000 gas to the callee
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}
