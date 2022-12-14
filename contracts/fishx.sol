// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NamiLandFishToken is ERC20("NamiLandFish", "FISHX"), Ownable {
    using SafeMath for uint;
    // The total supply of NFISH token is 1,000,000,000
    uint public maxSupply = 1000000000 * 1e18;
    // Trading of NFISH will be charged some fee.
    uint public taxRate = 0;
    // Trading fee charger.
    address public taxRecipient;

    // Backlist for trading, address which was added into blacklist will be charged fee.
    mapping(address => bool) public taxTransferBlacklist;
    mapping(address => bool) public taxTransferFromBlacklist;

    address public contractManager;

    constructor() {
        taxRecipient = owner();
        contractManager = owner();
        _mint(owner(), maxSupply);
    }

    // change fee rate, max rate should be less than 50%
    function changeTaxRate(uint newRate) external onlyManager {
        require(newRate <= 50, "tax rate is so high.");
        taxRate = newRate;
    }

    function changeTaxRecipient(address newAddress) external onlyManager {
        require(newAddress != address(0), "can not set 0 address.");
        taxRecipient = newAddress;
    }

    function burn(uint amount) external returns(bool) {
        require(amount > 0, "can not burn 0 token");
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) public override returns(bool) {
        require(balanceOf(msg.sender) >= amount, "insufficient balance.");
        // charge fee.
        uint256 taxAmount = 0;
        if (taxTransferBlacklist[msg.sender]) {
            taxAmount = amount.mul(taxRate).div(100);
        }
        uint256 transferAmount = amount.sub(taxAmount);
        super.transfer(recipient, transferAmount);
        if (taxAmount != 0) {
            super.transfer(taxRecipient, taxAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(balanceOf(sender) >= amount, "insufficient balance.");
        // For tax
        uint256 taxAmount = 0;
        if (taxTransferFromBlacklist[recipient]) {
            taxAmount = amount.mul(taxRate).div(100);
        }
        uint256 transferAmount = amount.sub(taxAmount);
        super.transferFrom(sender, recipient, transferAmount);
        if (taxAmount != 0) {
            super.transferFrom(sender, taxRecipient, taxAmount);
        }
        return true;
    }

    modifier onlyManager() {
        require(msg.sender == contractManager, "restrict for contract manager");
        _;
    }
}