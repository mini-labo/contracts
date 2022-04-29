pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "../MiniAuctionHouse.sol";
import "../proxies/MiniAuctionHouseProxy.sol";
import "../proxies/MiniAuctionHouseProxyAdmin.sol";
import "../MiniDataRepository.sol";
import "../MiniToken.sol";

contract Owner {
    MiniToken public miniToken;
    MiniAuctionHouseProxyAdmin public proxyAdmin;
    MiniAuctionHouseProxy public proxy;
    MiniDataRepository public miniDataRepository;
    MiniAuctionHouse public miniAuctionHouse;

    constructor() {
        miniAuctionHouse = new MiniAuctionHouse();
        miniDataRepository = new MiniDataRepository();
        miniToken = new MiniToken(address(miniDataRepository));
        proxyAdmin = new MiniAuctionHouseProxyAdmin();
        proxy = new MiniAuctionHouseProxy(address(miniAuctionHouse), address(proxyAdmin), "");

        MiniAuctionHouse(address(proxy)).initialize(
            IMiniToken(address(miniToken)),
            address(0),
            1,
            0.25 ether,
            5,
            666
        );
    }

    function initAuctionHouse(
      address _weth, 
      uint256 _timeBuffer, 
      uint256 _reservePrice, 
      uint8 _minBidIncrementPercentage,
      uint256 _duration
    ) public {
        miniAuctionHouse.initialize(miniToken, _weth, _timeBuffer, _reservePrice, _minBidIncrementPercentage, _duration);
    }

    function unpauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).unpause();
    }

    function pauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).pause();
    }

    function getCurrentAuction() public returns (MiniAuctionHouse.Auction memory) {
        MiniAuctionHouse(address(proxy)).auction();
    }

    function createNewBid(uint256 _miniId) public payable {
        MiniAuctionHouse(address(proxy)).createBid{ value: msg.value }(_miniId);
    }
}

contract User {
    MiniAuctionHouseProxy proxy;    

    constructor(address payable _proxyAddress) {
        proxy = MiniAuctionHouseProxy(_proxyAddress);
    }

    function unpauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).unpause();
    }

    function pauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).pause();
    }

    function getCurrentAuction() public returns (MiniAuctionHouse.Auction memory) {
        MiniAuctionHouse(address(proxy)).auction();
    }

    function createNewBid(uint256 _miniId) public payable {
        MiniAuctionHouse(address(proxy)).createBid{ value: msg.value }(_miniId);
    }
}

contract MiniAuctionHouseOwnerPauseTest is DSTest {
    Owner owner;
    
    function setUp() public {
        owner = new Owner();
    }

    function testOwnerUnpauseAuctionHouse() public {
        owner.unpauseAuctionHouse();
    }

    function testOwnerPauseAuctionHouse() public {
        owner.unpauseAuctionHouse();
        owner.pauseAuctionHouse();
    }
}

contract MiniAuctionHouseOwnerPlaceBidTest is DSTest {
    Owner owner;
    
    function setUp() public {
        owner = new Owner();
        owner.unpauseAuctionHouse();
    }

    function testOwnerCreateBid() public {
        owner.createNewBid{ value: 1 ether }(1);
    }

    function testFailOwnerCreateBidBelowReservePrice() public {
        owner.createNewBid{ value: 0.1 ether }(1);
    }
}

contract MiniAuctionHouseUserFailPauseTest is DSTest {
    Owner owner;
    User user;

    function setUp() public {
        owner = new Owner();
        owner.unpauseAuctionHouse();

        user = new User(payable(address(owner.proxy())));
    }

    function testFailUserUnpauseAuctionHouse() public {
        user.unpauseAuctionHouse();
    }

    function testFailUserPauseAuctionHouse() public {
        user.unpauseAuctionHouse();
        user.pauseAuctionHouse();
    }
}

contract MiniAuctionHouseUserPlaceBidTest is DSTest {
    Owner owner;
    User user;
    
    function setUp() public {
        owner = new Owner();
        owner.unpauseAuctionHouse();

        user = new User(payable(address(owner.proxy())));
    }

    function testUserCreateBid() public {
        user.createNewBid{ value: 1 ether }(1);
    }

    function testFailUserCreateBidBelowReservePrice() public {
        user.createNewBid{ value: 0.1 ether }(1);
    }
}
