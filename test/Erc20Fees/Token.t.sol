// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { TokenWithFees } from "../../contracts/Erc20Fees/TokenWithFees.sol";

interface Router {
    function WETH() external view returns(address);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
        external;
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract TokenTest is Test {
    address public deployer      = 0xba2D2fDe03831c9f05a83E4df2f12584E0f9E052;
    address public user1         = 0x9005eB5c85568aFEa80E5F6FEe34Cf20d948bc15;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint public tokenToMint = 1_000_000_000;

    TokenWithFees public rewardToken;
    TokenWithFees public token;
    Router public router;

    function setUp() public {
    // create mainnet fork
        uint mainnet = vm.createFork("https://rpc.ankr.com/eth", 17588467);
        vm.selectFork(mainnet);
    // fund users
        vm.deal(deployer, 100 ether);
        vm.deal(user1, 100 ether);
    // impersonate deployer
        vm.startPrank(deployer);
    // attach router
        router = Router(routerAddress);
    // deploy token
        token = new TokenWithFees(
            "TokenName",
            "TokenSymbol",
            tokenToMint,
            deployer
        );
    // label all the addresses
    vm.label(deployer, "deployer");
    vm.label(user1, "user1");
    vm.label(address(token), "token");
    vm.label(routerAddress, "router");
    vm.label(address(this), "TestContract");
    // add liquidity
        addLiquidity(token.balanceOf(deployer)/10, 10 ether);
    // exit deployer
        vm.stopPrank();
    }
    
// ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
// ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ██╔════╝
// ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     ███████╗
// ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     ╚════██║
// ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗███████║
// ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
    function addLiquidity(uint tokensInLiq, uint ETHInLiq) internal {
        token.approve(address(router), tokensInLiq);
        router.addLiquidityETH{value:ETHInLiq}(
            address(token),
            tokensInLiq,
            tokensInLiq,
            ETHInLiq,
            deployer,
            block.timestamp
        );
    }

    function getPath(bool _buy) internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        if(_buy) {
            path[0] = router.WETH();
            path[1] = address(token);
        } else {
            path[0] = address(token);
            path[1] = router.WETH();
        }
        return path;
    }

    function buyWithuser(uint256 amountETH) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokens{value: amountETH}(
            0,
            path,
            user1,
            block.timestamp
        );
    }

    function sellWithUser(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            user1,
            block.timestamp
        );
    }

    function getExpectedAmountOut(bool _buy, uint _amount) internal view returns(uint) {
        address[] memory path = getPath(_buy);
        uint[] memory amounts = router.getAmountsOut(_amount, path);
        return amounts[1];
    }

// ████████╗███████╗███████╗████████╗███████╗
// ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
//    ██║   █████╗  ███████╗   ██║   ███████╗
//    ██║   ██╔══╝  ╚════██║   ██║   ╚════██║
//    ██║   ███████╗███████║   ██║   ███████║
//    ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝

    function test_Trading() public {
        uint amount = 0.01 ether;
        // mock user
        vm.startPrank(user1);
        // buy path
        address[] memory path = getPath(true);
        // save how much tokens user should get
        (uint[] memory amounts) = router.getAmountsOut(amount, path);
        uint expectedAmount = amounts[1];
        // buy
        router.swapExactETHForTokens{value: amount}(
            0,
            path,
            user1,
            block.timestamp
        );

        // check user balance
        assert(token.balanceOf(user1) == expectedAmount);

    // sell all balance
        uint userBalance = token.balanceOf(user1);
        // approve for sell
        token.approve(address(router),userBalance);
        // sell path
        path = getPath(false);
        // save how much ETH user should get
        (amounts) = router.getAmountsOut(userBalance, path);
        expectedAmount = amounts[1];
        // sell
        router.swapExactTokensForETH(
            userBalance,
            expectedAmount,
            path,
            user1,
            block.timestamp
        );
        // check user balance
        assert(token.balanceOf(user1) == 0);
        
        vm.stopPrank();
    }
}
