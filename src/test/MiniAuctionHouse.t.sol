pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../MiniAuctionHouse.sol";
import "../proxies/MiniAuctionHouseProxy.sol";
import "../proxies/MiniAuctionHouseProxyAdmin.sol";
import "../MiniDataRepository.sol";
import "../MiniToken.sol";

address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

interface Vm {
  // Sets the block.timestamp number to `x`.
  function warp(uint256 x) external;

  // fuzzing variables must satisfy assume condition to run test case
  function assume(bool) external;
}

contract Owner {
    MiniToken public miniToken;
    MiniAuctionHouseProxyAdmin public proxyAdmin;
    MiniAuctionHouseProxy public proxy;
    MiniDataRepository public miniDataRepository;
    MiniAuctionHouse public miniAuctionHouse;

    receive() external payable {
        console.log('Owner receieved ETH payment:');
        console.log(msg.value);
    }

    constructor() {
        miniAuctionHouse = new MiniAuctionHouse();
        miniDataRepository = new MiniDataRepository();
        miniToken = new MiniToken(address(miniDataRepository));
        proxyAdmin = new MiniAuctionHouseProxyAdmin();
        proxy = new MiniAuctionHouseProxy(address(miniAuctionHouse), address(proxyAdmin), "");
        miniToken.setAuctionHouse(address(proxy));

        MiniAuctionHouse(address(proxy)).initialize(
            address(miniToken),
            address(miniDataRepository),
            address(0),
            1,
            0.25 ether,
            5,
            666
        );
    }

    function unpauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).unpause();
    }

    function pauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).pause();
    }

    function getCurrentAuction() public view returns (IMiniAuctionHouse.Auction memory _auction) {
        (
          uint256 _miniId, 
          uint256 _amount, 
          uint256 _startTime, 
          uint256 _endTime, 
          address payable _bidder, 
          bool _settled
        ) = MiniAuctionHouse(address(proxy)).auction();

        return IMiniAuctionHouse.Auction({
            miniId: _miniId,
            amount: _amount,
            startTime: _startTime,
            endTime: _endTime,
            bidder: _bidder,
            settled: _settled
        });
    }

    function createNewBid(uint256 _miniId) public payable {
        MiniAuctionHouse(address(proxy)).createBid{ value: msg.value }(_miniId);
    }

    function setArtistForId(uint256 _id, address _artist) public {
        miniDataRepository.setArtist(_id, _artist);
    }
}

contract User is IERC721Receiver {
    MiniAuctionHouseProxy proxy;    

    receive() external payable {
        console.log('User received ETH payment:');
        console.log(msg.value);
    }

    constructor(address payable _proxyAddress) {
        proxy = MiniAuctionHouseProxy(_proxyAddress);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function unpauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).unpause();
    }

    function pauseAuctionHouse() public {
        MiniAuctionHouse(address(proxy)).pause();
    }

    function createNewBid(uint256 _miniId) public payable {
        MiniAuctionHouse(address(proxy)).createBid{ value: msg.value }(_miniId);
    }

    function settleAuction() public {
        MiniAuctionHouse(address(proxy)).settleCurrentAndCreateNewAuction();
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
        owner.createNewBid{ value: 1 ether }(0);

        IMiniAuctionHouse.Auction memory currentAuction = owner.getCurrentAuction();
        assertEq(currentAuction.amount, 1 ether);
        assertEq(currentAuction.bidder, address(owner));
    }

    function testFailOwnerCreateBidBelowReservePrice() public {
        owner.createNewBid{ value: 0.1 ether }(0);
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
    Vm vm = Vm(CHEATCODE_ADDRESS);
    
    function setUp() public {
        owner = new Owner();
        owner.unpauseAuctionHouse();

        user = new User(payable(address(owner.proxy())));
    }

    function testUserCreateBid() public {
        user.createNewBid{ value: 1 ether }(0);

        IMiniAuctionHouse.Auction memory currentAuction = owner.getCurrentAuction();
        assertEq(currentAuction.amount, 1 ether);
        assertEq(currentAuction.bidder, address(user));
    }

    function testFailUserCreateBidBelowReservePrice() public {
        user.createNewBid{ value: 0.1 ether }(0);
    }

    function testUserBidRefundedWhenOutbid() public {
        User user2 = new User(payable(address(owner.proxy())));

        user.createNewBid{ value: 1 ether }(0);
        user2.createNewBid{ value: 1.25 ether }(0);

        assertEq(address(user).balance, 1 ether);
    }

    function testUserFuzzBidAmount(uint96 _amount) public {
        vm.assume(_amount > 0.27 ether);

        user.createNewBid{ value: _amount }(0);

        IMiniAuctionHouse.Auction memory currentAuction = owner.getCurrentAuction();
        assertEq(currentAuction.amount, _amount);
        assertEq(currentAuction.bidder, address(user));
    }

    function testUserBidAmountAndBidderUpdate() public {
        User user2 = new User(payable(address(owner.proxy())));

        user.createNewBid{ value: 1 ether }(0);
        user2.createNewBid{ value: 1.25 ether }(0);

        IMiniAuctionHouse.Auction memory currentAuction = owner.getCurrentAuction();
        assertEq(currentAuction.amount, 1.25 ether);
        assertEq(currentAuction.bidder, address(user2));
    }

    function testFailUserBidExpiredAuction() public {
        vm.warp(1000000);
        user.createNewBid{ value: 1 ether }(0);
    }
}

contract MiniAuctionHouseUserSettleAuctionTest is DSTest {
    Owner owner;
    User user;
    Vm vm = Vm(CHEATCODE_ADDRESS);

    function setUp() public {
        vm.warp(1); // non zero start time for contract logic
        owner = new Owner();
        owner.unpauseAuctionHouse();

        user = new User(payable(address(owner.proxy())));
        user.createNewBid{ value: 1 ether }(0);
    }

    function testFailUserSettleAuctionBeforeEndTime() public {
        vm.warp(2);
        user.settleAuction();
    }

    function testFailSettleAndCreateAuctionWhenAuctionHousePaused() public {
        vm.warp(668);
        owner.pauseAuctionHouse();
        user.settleAuction();
    }

    function testUserSettleAuction() public {
        // sanity check - user has no token to begin with
        assertEq(IERC721(address(owner.miniToken())).balanceOf(address(user)), 0);

        vm.warp(668);
        user.settleAuction();
        // user should receieve token
        assertEq(IERC721(address(owner.miniToken())).balanceOf(address(user)), 1);
        // new auction should have started - we can bid on the next ID
        user.createNewBid{ value: 1 ether }(1);
    }

    function testOtherUserCanSettleAuction() public {
        User user2 = new User(payable(address(owner.proxy())));

        vm.warp(668);
        user2.settleAuction();
        // user1 gets a token - they were the winning bidder
        assertEq(IERC721(address(owner.miniToken())).balanceOf(address(user)), 1);
        // user2 doesnt, they just settled
        assertEq(IERC721(address(owner.miniToken())).balanceOf(address(user2)), 0);
    }

    function testArtistProfitShare() public {
        User user2 = new User(payable(address(owner.proxy())));

        owner.setArtistForId(0, address(user2));
        vm.warp(668);
        user.settleAuction();
    }

    function testArtistProfitShareFuzzAmount(uint72 _amount) public {
        vm.assume(_amount > 1.1 ether);
        User user2 = new User(payable(address(owner.proxy())));

        user.createNewBid{ value: _amount }(0);

        IMiniAuctionHouse.Auction memory currentAuction = owner.getCurrentAuction();
        uint256 settledAuctionAmount = currentAuction.amount;

        owner.setArtistForId(0, address(user2));
        vm.warp(668);
        user.settleAuction();

        assertEq(address(user2).balance, (settledAuctionAmount / 100) * 40);
        assertEq(address(owner).balance, (settledAuctionAmount - (settledAuctionAmount / 100) * 40));
        assertGe(address(owner).balance, (settledAuctionAmount / 100) * 60); // sanity check - owner should end up with the remainder
    }
}
