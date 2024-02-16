// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
/**
 * @author karola96 | https://t.me/karola96 | https://kkteam.net
 */

import "forge-std/Script.sol";
import { TokenWithFees } from "../../contracts/Erc20Fees/TokenWithFees.sol";
import { IUniswapV2Router02 } from "../../contracts/shared/DexInterfaces.sol";



// used to configure the signer account
contract Base is Script {
    uint256 deployerPrivateKey = vm.envUint("PKEY_ACC1");
    address deployerAddress = vm.addr(deployerPrivateKey);

    modifier broadcast {
        vm.startBroadcast(deployerPrivateKey);
        _;
        vm.stopBroadcast();
    }
}

// define all the tasks of the project here
contract Tasks is Base {
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
    TokenWithFees token;

    function deployToken(string memory name, string memory symbol, uint _tokenToMint) public {
        token = new TokenWithFees(
            name,
            symbol,
            _tokenToMint,
            msg.sender
        );
    }

    function addLiquidityETH(
    address tokenAddress,
    uint amountETH,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline) public payable {
        router.addLiquidityETH{value: amountETH}(
            tokenAddress,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }
}

// run the tasks order here
// forge script .\scripts\deploy.s.sol:RunScripts --rpc-url mainnet
// pkey must have some eth
contract RunScripts is Tasks {
    uint public tokenToMint = 1_000_000_000;
    uint public ETHInLiq =    0.00001 ether;
    uint public tokensInLiq;
    
    function run() external broadcast {
    // deploy token
        deployToken("TokenName", "TokenSymbol", tokenToMint);
        tokensInLiq = token.balanceOf(deployerAddress) * 10 / 100; // 10% of tokens

    // approve
        token.approve(routerAddress, tokensInLiq);
    // add liquidity
        addLiquidityETH(
            address(token),
            ETHInLiq,
            tokenToMint,
            tokensInLiq,
            ETHInLiq,
            address(this),
            block.timestamp + 15 minutes
        );
    }
}