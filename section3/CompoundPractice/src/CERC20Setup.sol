// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {InterestRateModel} from "compound-protocol/contracts/InterestRateModel.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";

contract CERC20Setup {
    uint256 deployerPrivateKey;
    address deployerAddress;
    Comptroller comptroller;
    Comptroller uniTrollerProxy;
    WhitePaperInterestRateModel rateModel;
    SimplePriceOracle simpleOracle;
    Unitroller unitroller;

    CErc20Delegator CErc20DelegatorUSDC;
    CErc20Delegate CErc20delegateA;
    // UnderlyingTokenA underlyingTokenA;

    CErc20Delegator CErc20DelegatorUNI;
    CErc20Delegate CErc20delegateB;
    // UnderlyingTokenB underlyingTokenB;

    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    // CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    // CErc20 public cUNI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    function preDeploy() public {
        comptroller = new Comptroller();
        rateModel = new WhitePaperInterestRateModel(0, 0);
        CErc20delegateA = new CErc20Delegate();
        console.log("CErc20delegateA", address(CErc20delegateA));
        CErc20delegateB = new CErc20Delegate();
    }

    function deployUnitroller() public {
        // deploy unitroller and add configuration
        unitroller = new Unitroller();
        uniTrollerProxy = Comptroller(address(unitroller));
        // console.log("unitroller-proxy", address(unitrollerproxy));
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        // console.log("unitroller", address(unitroller));
    }

    function deployComptroller() public {
        // deply cerc20delegator
        //(    address underlying_,
        //     comptrollerinterface comptroller_,
        //     InterestRateModel interestratemodel_,
        //     uint initialexchangeratemantissa_,
        //     string memory name_,
        //     string memory symbol_,
        //     uint8 decimals_,
        //     address payable admin_,
        //     address implementation_ )
        console.log("USDC", address(USDC));
        CErc20DelegatorUSDC = new CErc20Delegator(
            address(USDC),
            Comptroller(address(unitroller)),
            InterestRateModel(rateModel),
            1e6,
            "ctoken usdc",
            "ctokenusdc",
            18,
            payable(address(this)),
            address(CErc20delegateA),
            "0x0"
        );
        CErc20DelegatorUNI = new CErc20Delegator(
            address(UNI),
            Comptroller(address(unitroller)),
            InterestRateModel(rateModel),
            1e18,
            "ctoken uni",
            "ctokenuni",
            18,
            payable(address(this)),
            address(CErc20delegateB),
            "0x0"
        );
    }

    function postDeploy() public {
        simpleOracle = new SimplePriceOracle();

        uniTrollerProxy._setPriceOracle(simpleOracle);
        // simpleOracle.setDirectPrice(address(USDC), 1);
        // simpleOracle.setDirectPrice(address(UNI), 5);
        simpleOracle.setUnderlyingPrice(
            CToken(address(CErc20DelegatorUSDC)),
            1e30
        );
        simpleOracle.setUnderlyingPrice(
            CToken(address(CErc20DelegatorUNI)),
            5 * 1e18
        );

        uniTrollerProxy._setLiquidationIncentive(1.08 * 1e18);
        uniTrollerProxy._supportMarket(CToken(address(CErc20DelegatorUSDC)));
        uniTrollerProxy._supportMarket(CToken(address(CErc20DelegatorUNI)));
        uniTrollerProxy._setCloseFactor(.5 * 1e18);
        uniTrollerProxy._setCollateralFactor(
            CToken(address(CErc20DelegatorUNI)),
            .5 * 1e18
        );
    }

    function setUpcErc20() public {
        preDeploy();
        deployUnitroller();
        deployComptroller();
        postDeploy();
    }
}
