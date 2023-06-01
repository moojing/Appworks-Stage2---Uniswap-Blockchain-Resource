// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/SimpleSwap.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SCRIPT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ERC20 token1 = new ERC20("Token1", "TK1");
        ERC20 token2 = new ERC20("Token2", "TK2");
        SimpleSwap swap = new SimpleSwap(address(token1), address(token2));

        vm.stopBroadcast();
    }
}

