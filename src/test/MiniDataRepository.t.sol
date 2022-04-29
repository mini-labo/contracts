pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "../MiniDataRepository.sol";
import "../MiniToken.sol";
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

    function setMiniTokenAddress(address _miniToken) public {
        miniDataRepository.setMiniTokenAddress(_miniToken);
    }

    function editTokenData(uint256 _id, bytes calldata _tokenMetadata) public {
        miniDataRepository.editData(_id, _tokenMetadata);
    }

    function returnTokenData(uint256 _id) public view returns (bytes memory) {
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

contract Curator {
    MiniDataRepository public miniDataRepository;

    constructor(MiniDataRepository _miniDataRepository) {
        miniDataRepository = _miniDataRepository;
    }

    function prepareTokenMetadata(string memory _imageData) public view returns (bytes memory) {
        return miniDataRepository.formatTokenData('test', 'test_description', '{\"test_attribute\":\"test\"}', _imageData);
    }

    function addTokenData(bytes memory _tokenMetadata) public {
        miniDataRepository.addData(_tokenMetadata);
    }

    function setMiniTokenAddress(address _miniToken) public {
        miniDataRepository.setMiniTokenAddress(_miniToken);
    }

    function editTokenData(uint256 _id, bytes calldata _tokenMetadata) public {
        miniDataRepository.editData(_id, _tokenMetadata);
    }

    function returnTokenData(uint256 _id) public view returns (bytes memory) {
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

contract MiniDataRepositoryOwnerTest is DSTest {
    Owner owner;
    Curator curatorCandidate;
    MiniToken miniToken;

    string public _genesisTokenImageData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    function setUp() public {
        owner = new Owner();
        curatorCandidate = new Curator(owner.miniDataRepository());
    }

    function testOwnerSetTokenAddress() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        owner.setMiniTokenAddress(address(miniToken));
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

    function testOwnerAddDataIdIncrement() public {
        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);
        assertEq(string(owner.returnTokenData(0)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(1)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(2)), string(bytesMetadata));
    }

    function testFailOwnerEditNextMintData() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        owner.setMiniTokenAddress(address(miniToken));

        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        owner.addTokenData(bytesMetadata);
        // ID 0 should fail as it is the "next" token to be minted
        owner.editTokenData(0, bytesMetadata);
    }

    function testOwnerCanEditFutureMintData() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        owner.setMiniTokenAddress(address(miniToken));

        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);
        owner.addTokenData(bytesMetadata);

        // ID 2 should succeed to be edited, as it has neither been minted nor is the next id to be minted
        owner.editTokenData(2, bytesMetadata);
    }
}

contract MiniDataRepositoryCuratorTest is DSTest {
    Owner owner;
    Curator curator;
    MiniToken miniToken;

    string public _genesisTokenImageData = 'data:image/svg+xml;base64,PHN2ZyBpbWFnZS1yZW5kZXJpbmc9InBpeGVsYXRlZCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pbllNaW4gbWVldCIgdmlld0JveD0iMCAwIDM1MCAzNTAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiID4gPGltYWdlIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHhsaW5rOmhyZWY9ImRhdGE6aW1hZ2UvYm1wO2Jhc2U2NCxRazBDQVFBQUFBQUFBSUlBQUFCc0FBQUFJQUFBQUNBQUFBQUJBQUVBQUFBQUFJQUFBQUFBQUFBQUFBQUFBQUlBQUFBQ0FBQUFBQUQvQUFEL0FBRC9BQUFBQUFBQS8wSkhVbk1BQUFBQUFBQUFBQUFBQUVBQUFBQUFBQUFBQUFBQUFFQUFBQUFBQUFBQUFBQUFBRUFBQUFBQUFBQUFBQUFBQUFELy8vOEFBQUFBQUFBQUFBQUFBQUFBQUE1d0FBQVJpQUFBRTVBQUFCLzRBQUIvL0FBQW4vb0FBSS82QUFCUDlBQUFKK2dBQUJad0FBQVA4QUFBRUFnQUFHQUVBQUQwSmdBRDlDY0FBZklYQUFINER3QUIvQThBQVA0ZkFBRC92Z0FBZi80QUFELzhBQUFmK0FBQUorUUFBRXBpQUFCQmtnQUFJa1FBQUJ3NEFBQUFBQUFBQUFBQSIgLz4gPC9zdmc+Cg==';

    function setUp() public {
        owner = new Owner();
        curator = new Curator(owner.miniDataRepository());
        owner.addCurator(address(curator)); 
    }

    function testFailCuratorSetTokenAddress() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        curator.setMiniTokenAddress(address(miniToken));
    }

    function testCuratorAddData() public {
        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        curator.addTokenData(bytesMetadata);
        assertEq(string(curator.returnTokenData(0)), string(bytesMetadata));
    }

    function testCuratorAddDataIdIncrement() public {
        bytes memory bytesMetadata = owner.prepareTokenMetadata(_genesisTokenImageData);
        curator.addTokenData(bytesMetadata);
        curator.addTokenData(bytesMetadata);
        curator.addTokenData(bytesMetadata);
        assertEq(string(owner.returnTokenData(0)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(1)), string(bytesMetadata));
        assertEq(string(owner.returnTokenData(2)), string(bytesMetadata));
    }

    function testFailCuratorEditNextMintData() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        owner.setMiniTokenAddress(address(miniToken));

        bytes memory bytesMetadata = curator.prepareTokenMetadata(_genesisTokenImageData);
        curator.addTokenData(bytesMetadata);
        // ID 0 should fail as it is the "next" token to be minted
        curator.editTokenData(0, bytesMetadata);
    }

    function testCuratorCanEditFutureMintData() public {
        miniToken = new MiniToken(address(owner.miniDataRepository.address));
        owner.setMiniTokenAddress(address(miniToken));

        bytes memory bytesMetadata = curator.prepareTokenMetadata(_genesisTokenImageData);
        curator.addTokenData(bytesMetadata);
        curator.addTokenData(bytesMetadata);
        curator.addTokenData(bytesMetadata);

        // ID 2 should succeed to be edited, as it has neither been minted nor is the next id to be minted
        curator.editTokenData(2, bytesMetadata);
    }
}
