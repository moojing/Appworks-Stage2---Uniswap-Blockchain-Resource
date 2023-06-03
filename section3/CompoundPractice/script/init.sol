
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { WhitePaperInterestRateModel } from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";

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

        // deply CErc20Delegator 
            // constructor(address underlying_,
            //     ComptrollerInterface comptroller_,
            //     InterestRateModel interestRateModel_,
            //     uint initialExchangeRateMantissa_,
            //     string memory name_,
            //     string memory symbol_,
            //     uint8 decimals_,
            //     address payable admin_,
            //     address implementation_,
            //     bytes memory becomeImplementationData) {
        CErc20Delegator delegator = new CErc20Delegator(
            address(underlyingToken),
            comptroller,
            rateModel,
            0,
            "cToken",
            "cToken",
            18,
            payable(address(this)),
            address(0),
            ""
        );
        vm.stopBroadcast();
    }
}
