require('solidity-coverage'); // npx hardhat coverage - runs tests and generates coverage report
require("hardhat-tracer"); // npx hardhat test --trace - runs tests and print traces in console
require("@nomicfoundation/hardhat-verify"); // npx hardhat verify ADDRESS --network networkToVerify (must be in config down there)
require("@nomicfoundation/hardhat-ethers"); // ethers.js in scripts/tests
require("@nomicfoundation/hardhat-foundry"); // to use same contracts lib
//require("hardhat-gas-reporter"); // npx hardhat test <-- enable only when needed - 
require("@nomicfoundation/hardhat-chai-matchers"); // expect on tests
require('@openzeppelin/hardhat-upgrades'); // openzeppelin upgradeable support for proxies
const crypto = require('crypto'); // random acc generator
require('dotenv').config({ path: __dirname + '/.env' }) // .env fileZ

// https://vanity-eth.tk/ <-- generate random vanced wallet/pkey

let AccountToSpawn = 10 // random account to spawn in localhost

// SET HERE THE PROJ PKEYS
const mainList = [
    process.env.PKEY_ACC1,
]

// temp. list to store mainnet accounts with ETH in localhost
let accountList = []
for (let i = 0; i < mainList.length; i++) {
  accountList.push({
    balance: "10000000000000000000000",//10k eth
    privateKey: mainList[i]
  })
}
// Additional accounts to add
if(AccountToSpawn > 0) {
  for (let i = 0; i < AccountToSpawn; i++) {
    accountList.push({
      balance: "10000000000000000000000",//10k ETH
      privateKey: "0x" + crypto.randomBytes(32).toString('hex') // random acc
    })
  }
}

// NETWORKS
MAINNET_URL = "https://rpc.ankr.com/eth"
POLYGON_URL = "https://rpc.ankr.com/polygon"
BSC_URL = "https://rpc.ankr.com/bsc"
GOERLI_URL = "https://rpc.ankr.com/eth_goerli"
MUMBAI_URL = "https://rpc.ankr.com/polygon_mumbai"
BSCTEST_URL = "https://rpc.ankr.com/bsc_testnet_chapel"
OPBNB_TEST_URL = "https://opbnb-testnet-rpc.bnbchain.org"

// CONFIG
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        }
      }
    ]
  },
  networks: {
    hardhat: {// de-comment to enable forks
      forking: {
        url: MAINNET_URL,
        blockNumber: 17588467, // fix the block to speed up tests
      },
      accounts: accountList,
      mining: { // useful to simulate real network in localhost
        auto: true,
        interval: 3000
      }
    },
    bscmain: {
      url: BSC_URL,
      accounts: mainList,
      gasPrice: 3000000000
    },
    bsctest: {
      url: BSCTEST_URL,
      accounts: mainList,
      gasPrice: 10000000000
    },
    bscoptest: {
      url: OPBNB_TEST_URL,
      accounts: mainList,
      gasPrice: 1510000000
    },
    mumbai: {
      url: MUMBAI_URL,
      accounts: mainList,
    },
    mainnet: {
      url: MAINNET_URL,
      accounts: mainList,
      gasPrice: 32000000000
    },
    goerli: {
      url: GOERLI_URL,
      accounts: mainList,
    },
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 35,
    token: "ETH",
    coinmarketcap: process.env.CMC_API_KEY
  },
  etherscan: {
    apiKey: {
      bsc: process.env.ETHERSCAN_API_KEY,
      hardhat: "abc"
    },
    customChains: [// custom contract verification for BlockScout docker
      {
        network: "hardhat",
        chainId: 31337,
        urls: {
          apiURL: "http://localhost:4000/api",
          browserURL: "http://localhost:4000/"
        }
      }
    ]
    // npx hardhat node
    // docker-compose up -d (on blockScout docker file folder)
    // run scripts/tests with --network localhost
    // npx hardhat verify ADDRESS --network localhost
    // go check http://localhost:4000 to navigate tx with verified contracts to check calls
    // can be hosted on VM and connected to your local pc in SSL
  }
};
