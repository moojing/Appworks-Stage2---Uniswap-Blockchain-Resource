
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { WhitePaperInterestRateModel } from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { SimplePriceOracle } from "compound-protocol/contracts/SimplePriceOracle.sol";
import { Comp } from "compound-protocol/contracts/Governance/Comp.sol";


contract MyScript is Script {
    Comptroller comptroller;
    
    function deployComptroller() public {
        // deploy underlying token 
        // deploy CErc20Delegate
        // datectory deploy CErc20Delegator
        ERC20 underlyingToken = new ERC20("underLying token", "UDT");
        WhitePaperInterestRateModel rateModel = new WhitePaperInterestRateModel(0,0);
        CErc20Delegate cErc20delegate = new CErc20Delegate();
        // deply CErc20Delegator 
        //(    address underlying_,
        //     ComptrollerInterface comptroller_,
        //     InterestRateModel interestRateModel_,
        //     uint initialExchangeRateMantissa_,
        //     string memory name_,
        //     string memory symbol_,
        //     uint8 decimals_,
        //     address payable admin_,
        //     address implementation_ ) 
        CErc20Delegator delegator = new CErc20Delegator(
            address(underlyingToken),
            comptroller,
            rateModel,
            1,
            "cToken",
            "cToken",
            18,
            payable(address(this)),
            address(cErc20delegate),
            "0x0"
        );
    }

    function deployUnitroller() public {
                // deploy unitroller and add configuration
        SimplePriceOracle simpleOracle = new SimplePriceOracle(); 
        Comp comp = new Comp(address(this));

        Unitroller unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        Comptroller(address(unitroller))._setLiquidationIncentive(1e18);
        Comptroller(address(unitroller))._setCloseFactor(.051 * 1e18);
        Comptroller(address(unitroller))._setPriceOracle(simpleOracle);
        Comptroller(address(unitroller))._setPriceOracle(simpleOracle);
    }

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("SCRIPT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        comptroller = new Comptroller();
        deployComptroller();
        deployUnitroller();

        vm.stopBroadcast();
    }
}
