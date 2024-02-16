const { ethers } = require("hardhat");

let chainId
let token
let tokenDecimals
let router
let owner
let routerAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
let tokenContractAddress = "0x9DEC830dD1f5Cf005005Ac6261D651fd85701B10"

async function initScripts() {
    // get the current chain ID
    const chainID = await ethers.provider.getNetwork()
    chainId = chainID.chainId
    console.log("script running on network ID: ", chainId)
    // assign the owner
    owner = await ethers.provider.getSigner(0)
    console.log("owner address: ", owner.address)
    // if you run a script and it's not a localhost network
    // you have 6 seconds to cancel it
    // better safe than sorry
    if (chainId != 31337) {
        console.log("sleep 6 sec..")
        await new Promise(r => setTimeout(r, 6000));
    }
}

async function deploy_token_contract() {
    const tokenName = "token Name";
    const tokenSymbol = "token Symbol";
    const totalSupply = 1000000; // 1M

    console.log("⚪Deploying token...")
    token = await (await ethers.getContractFactory("Token", owner)).deploy(
        tokenName,
        tokenSymbol,
        totalSupply
    )
    await token.waitForDeployment()
    console.log("✅token online on: %s", token.target);
}

async function attachContracts() {
    token = (await ethers.getContractFactory("Token", owner)).attach(tokenContractAddress)
    router = await ethers.getContractAt("IUniswapV2Router02", routerAddress, owner)
    tokenDecimals = await token.decimals()
    console.log("✅Contracts attached.")
}

async function addLiquidity() {
    const amount = ethers.parseUnits("100000", tokenDecimals)
    const amountETH = ethers.parseEther("10")
    
    console.log("⚪approving router...")
    let tx = await token.approve(routerAddress, ethers.MaxUint256)
    await tx.wait()
    console.log("Router approved.")

    console.log(`Ratio: ${amount/10n**tokenDecimals} Token:${amountETH/10n**18n} ETH`)
    console.log("⚪Adding liquidity...")
    tx = await router.addLiquidityETH(token,
        amount, // amountTokenDesired
        amount, // amountTokenMin
        amountETH, // amountETHMin
        owner, // to
        Date.now() + 600, // deadline
        { value: amountETH } // ETH
    )
    await tx.wait()
    console.log("✅Liquidity added.")
}

// ███╗   ███╗ █████╗ ██╗███╗   ██╗
// ████╗ ████║██╔══██╗██║████╗  ██║
// ██╔████╔██║███████║██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
async function runActions(stepToExecute) {
    console.log(`\n--🟡Executing script ${stepToExecute}🟡--\n`)
    switch (stepToExecute) {
        case 0: // deploy
            await deploy_token_contract()
            break
        case 1: // add liquidity
            await attachContracts()
            await addLiquidity()
            break
    }
}

async function run() {
    await initScripts()// always active pls
    const stepsToExecute = [0,1]

    for (let i = 0; i < stepsToExecute.length; i++) {
        currentStep = stepsToExecute[i]
        await runActions(currentStep)
        console.log(`\n--🟢Script ${stepsToExecute[i]} Done🟢--\n`)
    }
    console.log("All done.")
    process.exit()
}

run()