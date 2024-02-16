const { expect } = require("chai");

describe("Test init...", function () {
    /**
    In this section we create all the variables we need to test the token.
    Those are then used by any describe/it block below.
    This will alter the chain state and each test will run in the same context.
    Each test will run after the previous one in the altered chain state by the previous test.
     */

    let routerAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // uniswap v2
    let token; // the token we are testing
    let router; // uniswap router contract
    let factory; // uniswap factory contract
    let pair; // uniswap pair contract
    let WETH; // wrapped eth contract
    let owner; // deployer/owner
    let user; // user

    describe("Token Initialization", function () {
        it("init", async function () {
            // get accounts
            owner = await ethers.provider.getSigner(0); // deployer/owner
            user = await ethers.provider.getSigner(1); // user
        });
        it("deploy Token", async function () {
            const tokenName = "token Name";
            const tokenSymbol = "token Symbol";
            const totalSupply = 1000000; // 1M
            // deploy token
            token = await (await ethers.getContractFactory("Token", owner)).deploy(
                tokenName,
                tokenSymbol,
                totalSupply
            )
            // wait for token to be deployed
            await token.waitForDeployment();

            console.log("Token deployed to:", token.target);

            // attach router - we can use a contract with interfaces only to attach it
            router = await ethers.getContractAt("IUniswapV2Router02", routerAddress, owner);
            // or we can attach it with the factory but we must have a 1:1 interface on the contract
            // as long as we don't call any dedicated function of WETH, like deposit, we can use the interface or Token contract
            WETH = (await ethers.getContractFactory("Token", owner)).attach(await router.WETH());

            // to add names on "npx hardhat test --trace"
            hre.tracer.nameTags[routerAddress] = "UniswapV2Router02"
            hre.tracer.nameTags[token] = await token.name()
            hre.tracer.nameTags[owner] = "Owner"
            hre.tracer.nameTags[user] = "User"

            // total supply should be 100% in deployer/owner's wallet
            expect(await token.balanceOf(owner)).to.equal(await token.totalSupply());
        });

        it("add Liquidity", async function () {

            // half token supply
            let amount = await token.totalSupply() / 2n
            // 10 ETH
            let amountETH = ethers.parseEther("10")

            // approve router to move tokens with transferFrom
            tx = await token.approve(router, amount)
            await tx.wait()

            // add liquidity
            // we add half of the total supply of tokens and 10 ETH
            tx = await router.addLiquidityETH(token, amount, amount, amountETH, owner, Date.now() + 600, { value: amountETH })
            receipt = await tx.wait()

            // setup the factory contract, get it from the router
            factory = await ethers.getContractAt("IUniswapV2Factory", await router.factory(), owner)
            // get the pair address
            pairAddress = await factory.getPair(token, WETH)
            // setup the pair contract
            pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress, owner)
            
            // check if the pair has the correct reserves
            reserves = await pair.getReserves()
            expect(reserves[0]).to.equal(amount)
            expect(reserves[1]).to.equal(amountETH)
        });
    });

    describe("Token actions", function () {

        it("do a buy", async function () {
            // buy

            // notice: we created the Router contract object with the owner account as signer
            // so we need to use .connect to let the user interact with that contract
            let tx = await router.connect(user).swapExactETHForTokens(
                1, // minAmountToken
                [WETH, token], // path
                user, // recipient
                Date.now() + 60, // deadline
                { value: ethers.parseEther("1") } // ETH amount
            );
            await tx.wait()
        });

        it("do a sell", async function () {
            // get user token balance
            let balance = await token.balanceOf(user);
            // get token decimals
            let tokenDecimals = await token.decimals();
            console.log("User token balance before selling: ", ethers.formatUnits(balance, tokenDecimals));

            // approve router to move tokens
            let approve = await token.connect(user).approve(routerAddress, "10000000000000000000000000000000");
            await approve.wait();

            // sell
            const tx = await router.connect(user).swapExactTokensForETH(
                balance,
                1,
                [token, WETH],
                user,
                Date.now() + 60
            );
            await tx.wait();
            console.log("User token balance after selling: ", ethers.formatUnits(await token.balanceOf(user), tokenDecimals));
            // user balance should be 0
            expect(await token.balanceOf(user)).to.equal(0);
        });
    });
});
