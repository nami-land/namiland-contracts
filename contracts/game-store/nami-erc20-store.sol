// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NecoFishingItemStore is Ownable {
    IERC20 public erc20Token;

    address public devAccount;
    address public operator;

    event DepositTokenSuccessfully(address indexed from, address indexed to, uint amount);
    event WithdrawTokenSuccessfully(address indexed to, uint amount);

    constructor(IERC20 _erc20Token, address _devAccount, address _operator) {
        erc20Token = _erc20Token;
        devAccount = _devAccount;
        operator = _operator;
    }

    function changeErc20ContractAddress(IERC20 newAddress) external onlyOwner {
        erc20Token = newAddress;
    }

    function changeDevAccount(address newAccount) external onlyOwner {
        devAccount = newAccount;
    }

    function changeOperatorAccount(address newAccount) external onlyOwner {
        operator = newAccount;
    }

    function depositToken(uint amount) external {
        erc20Token.transferFrom(msg.sender, address(this), amount);
        emit DepositTokenSuccessfully(msg.sender, address(this), amount);
    }

    function withdrawToken(address to, uint amount) external onlyOperator {
        require(amount > 0, "incorrect amount");
        uint balance = erc20Token.balanceOf(address(this));
        require(amount <= balance, "Out of balance.");
        erc20Token.transfer(to, amount);
        emit WithdrawTokenSuccessfully(to, amount);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "restrict for operator.");
        _;
    }

    function emergencyWithdrawToken() external onlyOwner {
        uint balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(owner(), balance);
    }
}