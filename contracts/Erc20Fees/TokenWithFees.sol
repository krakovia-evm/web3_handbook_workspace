// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenWithFees
 * @author Krakovia | t.me/karola96
 * @notice ERC20 token with minting capabilities at deployment & fees
 */
contract TokenWithFees is ERC20, Ownable {
    address public feeReceiver;
    address public pair;
    Fees public fees;

    struct Fees {
        uint buy;
        uint sell;
        uint transfer;
        uint burn;
    }

    event FeesSet(uint buy, uint sell, uint transfer, uint burn);
    event FeeReceiverSet(address feeReceiver);
    event PairSet(address pair);
    event FeeCollected(address from, address to, uint amount);

    constructor(string memory tokenName, string memory tokenSymbol, uint tokensToMint, address _feeReceiver) ERC20(tokenName, tokenSymbol) Ownable(msg.sender) {
        _mint(msg.sender, tokensToMint * 10 ** decimals());
        feeReceiver = _feeReceiver;
    }

    function setFees(uint buy, uint sell, uint transfer_, uint burn) external onlyOwner {
        require(buy + sell + transfer_ + burn <= 20, "Fees must be equal or less then 20%");
        fees = Fees(buy, sell, transfer_, burn);
        emit FeesSet(buy, sell, transfer_, burn);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(feeReceiver);
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
        emit PairSet(pair);
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        uint tradeType = 0; // by default, it's a transfer
        uint fee;
    // checks
        require(amount != 0, "Amount must be greater then 0");
    // getting order type
        if (sender == pair) { // buy
            tradeType = 1;
            fee = amount * fees.buy / 100;
        } else if (recipient == pair) { // sell
            tradeType = 2;
            fee = amount * fees.sell / 100;
        } else {
            fee = amount * fees.transfer / 100;
        }
    // apply fee if necessary
        if (fee > 0) {
            amount -= fee;
            super._update(sender, feeReceiver, fee);
            emit FeeCollected(sender, feeReceiver, fee);
        }
    // transfer tokens
        super._update(sender, recipient, amount);
    }
}