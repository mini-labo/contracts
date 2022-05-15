pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../MiniToken.sol";
import "../MiniDataRepository.sol";
import "../MiniAuctionHouse.sol";

address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
address constant FAKE_AUCTION_HOUSE_ADDRESS = 0x55555AaaaaAAAaAaAaaAAAAAa5A8f67f5b1dD12D;

interface Vm {
  // Send next call as different address
  function prank(address sender) external;

  // start prank that will end with stop call or end of transaction
  function startPrank(address sender) external;
  function stopPrank() external;
}

contract User is IERC721Receiver {
    MiniToken m;
    Vm vm = Vm(CHEATCODE_ADDRESS);

    constructor (MiniToken _m) {
        m = _m;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function mintMiniToken() public {
        vm.startPrank(FAKE_AUCTION_HOUSE_ADDRESS);
        m.mintTokenTo(address(this));
        vm.stopPrank();
    }

    // not pranking as auction house
    function attemptMintAsOrdinaryUser() public {
        m.mintTokenTo(address(this));
    }
}

contract MiniTokenTest is DSTest {
    MiniToken minitoken;
    MiniDataRepository dataRepository;
    User user;

    bytes public genesisByteData;
    string public genesisJsonData;

    string public _genesisTokenData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    function setUp() public {
        dataRepository = new MiniDataRepository();
        minitoken = new MiniToken(address(dataRepository)); 
        minitoken.setAuctionHouse(address(FAKE_AUCTION_HOUSE_ADDRESS));

        genesisByteData = abi.encode('test', 'test_description', 'three', '1', _genesisTokenData);
        genesisJsonData = dataRepository.formatTokenJson('test', 'test_description', 'three', '1', _genesisTokenData);
        dataRepository.setMiniTokenAddress(address(minitoken));
        dataRepository.addData(genesisByteData);

        user = new User(minitoken);
    }

    function testInitialTokenCounter() public {
        assertEq(minitoken.tokenCounter(), 0);
    }

    function testMint() public {
        user.mintMiniToken();
        assertEq(minitoken.tokenCounter(), 1);
    }

    function testFailUserMint() public {
        user.attemptMintAsOrdinaryUser();
    }

    function testURIRetrieval() public {
        user.mintMiniToken();
        assertEq(minitoken.tokenURI(0), genesisJsonData);
        console.log(minitoken.tokenURI(0));
    }

    function testMintIncrementTokenId() public {
        dataRepository.addData(genesisByteData); // data inserted for id 1

        user.mintMiniToken();
        user.mintMiniToken();
        user.mintMiniToken();

        assertEq(minitoken.tokenURI(0), dataRepository.tokenData(0));
        assertEq(minitoken.tokenURI(1), dataRepository.tokenData(1)); 
    }

    function testFailNonExistingTokenId() public {
        minitoken.tokenURI(99);
    }
}
