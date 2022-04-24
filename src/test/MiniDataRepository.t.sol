pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "../MiniDataRepository.sol";
import "base64/base64.sol";

contract Owner {
    MiniDataRepository public miniDataRepository;

    constructor() {
        miniDataRepository = new MiniDataRepository();
    }

    function prepareTokenMetadata(string memory _imageData) public view returns (bytes memory) {
        return miniDataRepository.formatTokenData('test', 'test_description', '{\"test_attribute\":\"test\"}', _imageData);
    }

    function addTokenData(bytes memory _tokenMetadata) public {
        miniDataRepository.addData(_tokenMetadata);
    }

    function returnTokenData(uint256 _id) public returns (bytes memory) {
        return miniDataRepository.tokenMetadata(_id);
    }

    function addCurator(address _newCurator) public {
        miniDataRepository.addCurator(_newCurator);
    }

    function removeCurator(address _oldCurator) public {
        miniDataRepository.removeCurator(_oldCurator);
    }

    function checkIfCurator(address _address) public view returns (bool) {
        return miniDataRepository.isCurator(_address);
    }
}

contract Curator {}

contract MiniDataRepositoryOwnerTest is DSTest {
    Owner owner;
    Curator curatorCandidate;
    string public _genesisTokenImageData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    function setUp() public {
        owner = new Owner();
        curatorCandidate = new Curator();
    }

    function testOwnerAddCurator() public {
        owner.addCurator(address(curatorCandidate)); 
        assert(owner.checkIfCurator(address(curatorCandidate)));
    }

    function testOwnerRemoveCurator() public {
        owner.addCurator(address(curatorCandidate)); 
        assert(owner.checkIfCurator(address(curatorCandidate)));
        owner.removeCurator(address(curatorCandidate)); 
        assert(!(owner.checkIfCurator(address(curatorCandidate))));
    }

    function testOwnerAddData() public {
        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        owner.addTokenData(bytesMetadata);
        assertEq(string(owner.returnTokenData(0)), string(bytesMetadata));
    }

    function testAddDataIdIncrement() public {
        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);
        assertEq(string(owner.returnTokenData(0)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(1)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(2)), string(bytesMetadata));
    }
}
