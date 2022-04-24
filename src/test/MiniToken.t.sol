pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../MiniToken.sol";
import "../MiniDataRepository.sol";

contract User is IERC721Receiver {
    MiniToken m;

    constructor (MiniToken _m) {
        m = _m;
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function mintMiniToken() public {
        m.mintToken();
    }
}

contract MiniTokenTest is DSTest {
    MiniToken minitoken;
    MiniDataRepository dataRepository;
    User user;

    string public _genesisTokenData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    function setUp() public {
        dataRepository = new MiniDataRepository();
        minitoken = new MiniToken(address(dataRepository)); 
        bytes memory genesisTokenData = dataRepository.formatTokenData('test', 'test_description', '{\"test_attribute\":\"test\"}', _genesisTokenData);
        dataRepository.setMiniTokenAddress(address(minitoken));
        dataRepository.addData(genesisTokenData);
        user = new User(minitoken);
    }

    function testInitialTokenCounter() public {
        assertEq(minitoken.tokenCounter(), 0);
    }

    function testMint() public {
        user.mintMiniToken();
        assertEq(minitoken.tokenCounter(), 1);
    }

    function testURIRetrieval() public {
        user.mintMiniToken();
        console.log(minitoken.tokenURI(0));
    }
}
