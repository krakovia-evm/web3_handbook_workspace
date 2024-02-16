// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { TokenAirdrop } from "../../contracts/Erc20/TokenAirdrop.sol";

contract AirdropTest is Test {
    TokenAirdrop token;
    uint totalSupply = 100_000;
    function setUp() public {
        // deploy ERC20 token
        token = new TokenAirdrop("MyToken", "MTK", totalSupply);
    }

    function test_token_deployed() public {
        assertEq(token.balanceOf(address(this)), totalSupply*10**token.decimals());
    }

    function test_airdrop() public {
        uint currentBalance = token.balanceOf(address(this));
        uint accounts = 10;
        uint amountToAirdrop = 10000;
        // create a list of addresses and amounts
        address[] memory addresses = new address[](accounts);
        uint[] memory amounts = new uint[](accounts);
        
        // populate lists
        for (uint i = 0; i < accounts; i++) {
            addresses[i] = vm.addr(i+100000);
            amounts[i] = amountToAirdrop / accounts;
        }

        // make the airdrop
        token.airdrop(addresses, amounts);

        // contract should have 10000 less tokens
        assertEq(token.balanceOf(address(this)), currentBalance - amountToAirdrop);
        // each address should have 1000 tokens
        for (uint i = 0; i < accounts; i++) {
            assertEq(token.balanceOf(addresses[i]), amountToAirdrop / accounts);
        }
    }
}