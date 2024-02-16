// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
// this is the original ERC20 contract from OpenZeppelin and it's an official Ethereum standard
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenAirdrop
 * @author Krakovia | t.me/karola96
 * @notice ERC20 token with minting capabilities at deployment & airdrop function
 */
contract TokenAirdrop is ERC20 {

    /**
     * @notice deploys the token and mints the initial supply
     * @param tokenName name of the token
     * @param tokenSymbol symbol of the token
     * @param tokensToMint total amount of tokens to mint
     */
    constructor(string memory tokenName, string memory tokenSymbol, uint tokensToMint) ERC20(tokenName, tokenSymbol) {
        // call internal mint function to mint the initial supply
        // as it's an internal function, it's called only here so the supply is fixed.
        // we send the tokens to the deployer of the contract
        // on EVM you cannot have 0.1 tokens, so we multiply the amount by 10^decimals
        // decimals is a public function from ERC20.sol
        _mint(msg.sender, tokensToMint * 10 ** decimals());
    }

    function airdrop(address[] memory addresses, uint[] memory amounts) external {
        // loop through the addresses array and send the tokens
        for (uint i = 0; i < addresses.length; i++) {
            // transfer the tokens from the sender to the current address in the loop
            super._transfer(msg.sender, addresses[i], amounts[i]);
        }
    }
}