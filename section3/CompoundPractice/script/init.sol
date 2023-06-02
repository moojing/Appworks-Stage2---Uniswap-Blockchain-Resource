
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/SimpleSwap.sol";

import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { WhitePaperInterestRateModel } from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";

contract MyScript is Script {
    function run() external {
        // deploy underlying token 
        // deploy CErc20Delegate
        // datectory deploy CErc20Delegator

        uint256 deployerPrivateKey = vm.envUint("SCRIPT_PRIVATE_KEY");
        ERC20 underlyingToken = new ERC20("underLying token", "UDT");

        vm.startBroadcast(deployerPrivateKey);
        Comptroller comptroller = new Comptroller();
        WhitePaperInterestRateModel rateModel = new WhitePaperInterestRateModel(0,0);

        // SimpleSwap swap = new SimpleSwap(address(token1), address(token2));

        vm.stopBroadcast();
    }
}
