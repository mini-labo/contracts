pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../MiniToken.sol";

contract TestMiniToken is Mini {}

contract User is IERC721Receiver {
    TestMiniToken m;

    string public _genesisTokenData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    constructor (TestMiniToken _m) {
        m = _m;
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4) {
        string memory tokenMetadata = m.tokenURI(_tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function mintMiniToken() public {
        m.mintToken(_genesisTokenData);
    }

    function getURIFormat(string memory tokenData) public view {
        bytes memory bytesData = bytes(tokenData);
        bytes memory data = m.formatTokenData(bytesData);
        console.log(string(data));
    }
}

contract MiniTokenTest is DSTest {
    TestMiniToken minitoken;
    User user;

    function setUp() public {
        minitoken = new TestMiniToken(); 
        user = new User(minitoken);
    }

    function testInitialTokenCounter() public {
        assertEq(minitoken.tokenCounter(), 0);
    }

    function testMint() public {
        user.mintMiniToken();
        assertEq(minitoken.tokenCounter(), 1);
    }

    function testURIFormat() public {
        user.getURIFormat(user._genesisTokenData());
    }

    function testURIRetrieval() public {
        user.mintMiniToken();
        console.log(minitoken.tokenURI(0));
    }
}
