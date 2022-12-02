// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NamiLandToken is ERC20("NamiLand", "NAMIX"), Ownable {
    using SafeMath for uint;

    bool public transferLocked = true;
    uint public maxSupply = 10000000000 * 1e18;

    uint public taxRate = 0;
    address public taxRecipient;
    mapping(address => bool) public taxTransferBlacklist;
    mapping(address => bool) public taxTransferFromBlacklist;
    mapping(address => bool) public transferWhitelist;

    address public contractManager;

    constructor() {
        taxRecipient = owner();
        contractManager = owner();
        _mint(owner(), maxSupply);
    }

    function changeNewManager(address manager) external onlyManager {
        contractManager = manager;
    }

    function addToTaxTransferBlacklist(address account) external onlyManager {
        taxTransferBlacklist[account] = true;
    }

    function removeFromTaxTransferBlacklist(address account) external onlyManager {
        taxTransferBlacklist[account] = false;
    }

    function addToTaxTransferFromBlacklist(address account) external onlyManager {
        taxTransferFromBlacklist[account] = true;
    }

    function removeFromTaxTransferFromBlacklist(address account) external onlyManager {
        taxTransferFromBlacklist[account] = false;
    }

    function addToTransferWhitelist(address account) external onlyManager {
        transferWhitelist[account] = true;
    }

    function removeFromTransferWhitelist(address account) external onlyManager {
        transferWhitelist[account] = false;
    }

    function changeTaxRate(uint newRate) external onlyManager {
        require(newRate <= 50, "tax rate is so high.");
        taxRate = newRate;
    }

    function changeTaxRecipient(address newAddress) external onlyManager {
        require(newAddress != address(0), "can not set 0 address.");
        taxRecipient = newAddress;
    }

    // only user can burn their own NECO tokens.
    function burn(uint amount) external {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }

    function transfer(address recipient, uint amount) public override returns(bool) {
        require(transferWhitelist[msg.sender] || !transferLocked, "Bad Transfer");
        require(balanceOf(msg.sender) >= amount, "insufficient balance.");
        // Tax
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
        require(transferWhitelist[sender] || !transferLocked, "Bad transferFrom");
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

    // once unlock transfer function, we can not lock it again.
    function unlockTransfer() external onlyManager {
        require(transferLocked == true, "Trasfer function is already unlocked.");
        transferLocked = false;
    }

    modifier onlyManager() {
        require(msg.sender == contractManager, "restrict for contract manager");
        _;
    }
}