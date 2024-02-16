// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Airdrop
 * @author Krakovia | t.me/karola96
 * @notice Contract to distribute ERC20 tokens to multiple addresses
 */
contract Airdrop {
    
    function AirdropERC20TokensSingleAmount(address tokenAddress, address[] memory addresses, uint amount) external {
        // loop through the addresses array and send the tokens
        for (uint i = 0; i < addresses.length; i++) {
            // transfer the tokens from the sender to the current address in the loop
            IERC20(tokenAddress).transferFrom(msg.sender, addresses[i], amount);
        }
    }

    function AirdropERC20Tokens(address tokenAddress, address[] memory addresses, uint[] memory amounts) external {
        // loop through the addresses array and send the tokens
        for (uint i = 0; i < addresses.length; i++) {
            // transfer the tokens from the sender to the current address in the loop
            IERC20(tokenAddress).transferFrom(msg.sender, addresses[i], amounts[i]);
        }
    }

    // function by @PopPunkOnChain on X
    // https://basescan.org/address/0x09350f89e2d7b6e96ba730783c2d76137b045fef#code
    function AirdropERC20GasBadEdition(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _totalAmount
    ) external payable {
        assembly {
            // Check that the number of addresses matches the number of amounts
            if iszero(eq(_amounts.length, _addresses.length)) {
                revert(0, 0)
            }

            // transferFrom(address from, address to, uint256 amount)
            mstore(0x00, hex"23b872dd")
            // from address
            mstore(0x04, caller())
            // to address (this contract)
            mstore(0x24, address())
            // total amount
            mstore(0x44, _totalAmount)

            // transfer total amount to this contract
            if iszero(call(gas(), _token, 0, 0x00, 0x64, 0, 0)){
                revert(0, 0)
            }

            // transfer(address to, uint256 value)
            mstore(0x00, hex"a9059cbb")

            // end of array
            let end := add(_addresses.offset, shl(5, _addresses.length))
            // diff = _addresses.offset - _amounts.offset
            let diff := sub(_addresses.offset, _amounts.offset)

            // Loop through the addresses
            for { let addressOffset := _addresses.offset } 1 {} {
                // to address
                mstore(0x04, calldataload(addressOffset))
                // amount
                mstore(0x24, calldataload(sub(addressOffset, diff)))
                // transfer the tokens
                if iszero(call(gas(), _token, 0, 0x00, 0x64, 0, 0)){
                    revert(0, 0)
                }
                // increment the address offset
                addressOffset := add(addressOffset, 0x20)
                // if addressOffset >= end, break
                if iszero(lt(addressOffset, end)) { break }
            }
        }
    }
}