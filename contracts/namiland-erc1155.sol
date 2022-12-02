// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NamiLandERC1155 is ERC1155, ERC1155Burnable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    mapping(address => bool) public minters;
    EnumerableSet.UintSet private _tokenIds;
    EnumerableSet.UintSet private _lockedTokenIds;

    mapping(uint => uint) public totalSupply;
    mapping(address => bool) public transferWhitelist;

    string public name;
    string public symbol;
    string public baseTokenURI;

    constructor(string memory _uri, string memory _name, string memory _symbol) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        baseTokenURI = _uri;
    }

    event Mint(uint indexed tokenId, address indexed to, uint quantity);

    // change the contract name
    function changeName(string memory _name) public onlyOwner {
        name = _name;
    }

    // change the contract symbol
    function changeSymbol(string memory _symbol) public onlyOwner {
        symbol = _symbol;
    }

    function mint(uint tokenId, address to, uint quantity, bytes memory data) external onlyMinter {
        require(quantity > 0, "quantity cannot be 0!");
        totalSupply[tokenId] = totalSupply[tokenId].add(quantity);
        _mint(to, tokenId, quantity, data);

        emit Mint(tokenId, to, quantity);
    }

    function changeBaseUri(string memory _newUri) external onlyOwner {
        bytes memory uriBytes = bytes(_newUri);
        require(uriBytes.length != 0, "uri can not be null");
        baseTokenURI = _newUri;
    }

    function uri(uint id) public override view returns(string memory) {
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, id.toString())) : "";
    }

    function setMinter(address account, bool isMinter) external onlyOwner {
        require(account != address(0), "minter can not be address 0");
        minters[account] = isMinter;
    }

    function addLockedNFT(uint id) external onlyOwner {
        _lockedTokenIds.add(id);
    }

    function cancelLockedNFT(uint id) external onlyOwner {
        _lockedTokenIds.remove(id);
    }

    function getTokenIdsLength() public view returns(uint) {
        return _tokenIds.length();
    }

    function getTokenIdByIndex(uint index) public view returns(uint) {
        return _tokenIds.at(index);
    }

    function getLockedTokenIdsLength() public view returns(uint) {
        return _lockedTokenIds.length();
    }

    function getLockedTokenIdsByIndex(uint index) public view returns(uint) {
        return _lockedTokenIds.at(index);
    }

    function addIntoTransferWhitelist(address account) external onlyOwner {
        require(account != address(0), "Account is 0");
        transferWhitelist[account] = true;
    }

    function removeFromTransferWhitelist(address account) external onlyOwner {
        require(account != address(0), "Account is 0");
        transferWhitelist[account] = false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(!_lockedTokenIds.contains(id) || transferWhitelist[from], "NFT is locked.");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        if (!transferWhitelist[from]) {
            for(uint i = 0; i < ids.length; i ++) {
                uint id = ids[i];
                if (_lockedTokenIds.contains(id)) {
                    revert("Batch of NFT contains locked NFT!");
                }
            }
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    modifier onlyMinter() {
        require(minters[msg.sender] == true, "restrict for minters!");
        _;
    }
}