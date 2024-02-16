// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TokenAirdrop } from "../../contracts/Erc20/TokenAirdrop.sol";

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
    TokenAirdrop token;

    function deployToken(string memory name, string memory symbol, uint _tokenToMint) public {
        token = new TokenAirdrop(
            name,
            symbol,
            _tokenToMint
        );
    }
}

contract RunScripts is Tasks {
    function run() external broadcast {
    // deploy token
        deployToken("TokenName", "TokenSymbol", 100_000);
    }
}