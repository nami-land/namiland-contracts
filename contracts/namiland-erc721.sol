// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NamiLandERC721 is ERC721, ERC721Burnable, Ownable {
    string public baseTokenURI;
    mapping(address => bool) public minterWhitelist;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address to, uint tokenId) external onlyMinter {
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    function setMinter(address minter, bool isMinter) external onlyOwner {
        minterWhitelist[minter] = isMinter;
    }

    modifier onlyMinter() {
        require(minterWhitelist[msg.sender], "NamiLandERC721: caller is not the minter");
        _;
    }
}