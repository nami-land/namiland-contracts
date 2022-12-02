// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./INamiNFT.sol";

contract NamiLandGameNFTStore is Ownable, ERC1155Holder {
    INamiNFT public namiGameNFT;
    address public devAccount;
    address public operator;

    event DepositBatchNFTSuccessfully(address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event WithdrawBatchNFTsSuccessfully(address indexed to, uint256[] ids, uint256[] values);

    constructor(INamiNFT _namiNFT, address _devAccount, address _operator) {
        namiGameNFT = _namiNFT;
        devAccount = _devAccount;
        operator = _operator;
    }

    function changeNFTContractAddress(INamiNFT _newNFT) external onlyOwner {
        namiGameNFT = _newNFT;
    }

    function changeDevAccount(address newAccount) external onlyOwner {
        devAccount = newAccount;
    }

    function changeOperatorAccount(address newAccount) external onlyOwner {
        operator = newAccount;
    }

    function withdrawBatchNFTs(address to, uint256[] calldata nftIds, uint256[] calldata amounts) external onlyOperator {
        uint length = nftIds.length;
        for (uint i = 0; i < length; i++) {
            require(amounts[i] > 0, "amout cannot be 0");
            namiGameNFT.mint(nftIds[i], address(this), amounts[i], "Withdraw from Namiland");
        }

        namiGameNFT.safeBatchTransferFrom(address(this), to, nftIds, amounts, "Withdraw from NamiLand");
        emit WithdrawBatchNFTsSuccessfully(to, nftIds, amounts);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "restrict for operator.");
        _;
    }
}