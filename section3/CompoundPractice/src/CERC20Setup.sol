// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {CompScript} from "./comp.sol";
import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";
import {WhitePaperInterestRateModel} from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import {CErc20Delegate} from "compound-protocol/contracts/CErc20Delegate.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";
import {CErc20Delegator} from "compound-protocol/contracts/CErc20Delegator.sol";
import {Unitroller} from "compound-protocol/contracts/Unitroller.sol";
import {InterestRateModel} from "compound-protocol/contracts/InterestRateModel.sol";
import {SimplePriceOracle} from "compound-protocol/contracts/SimplePriceOracle.sol";
import {Comp} from "compound-protocol/contracts/Governance/Comp.sol";
import {GovernorBravoDelegate} from "../contract/BravoDelegateCustom.sol";
import {GovernorBravoDelegator} from "compound-protocol/contracts/Governance/GovernorBravoDelegator.sol";
import {GovernorAlpha} from "compound-protocol/contracts/Governance/GovernorAlpha.sol";

contract UnderlyingToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract UnderlyingTokenA is UnderlyingToken {
    constructor() UnderlyingToken("underlying token A", "UDT-A") {}
}

contract UnderlyingTokenB is UnderlyingToken {
    constructor() UnderlyingToken("underlying token B", "UDT-B") {}
}

contract CERC20Setup {
    uint256 deployerPrivateKey;
    address deployerAddress;
    Comptroller comptroller;
    Comptroller uniTrollerProxy;
    WhitePaperInterestRateModel rateModel;
    Unitroller unitroller;

    CErc20Delegator cErc20DelegatorA;
    CErc20Delegate cErc20delegateA;
    UnderlyingTokenA underlyingTokenA;

    CErc20Delegator cErc20DelegatorB;
    CErc20Delegate cErc20delegateB;
    UnderlyingTokenB underlyingTokenB;
    SimplePriceOracle simpleOracle;

    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    CErc20 public cDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    function preDeploy() public {
        comptroller = new Comptroller();
        rateModel = new WhitePaperInterestRateModel(0, 0);
    }

    function deployComptroller() public {
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
        cErc20DelegatorA = new CErc20Delegator(
            address(underlyingTokenA),
            Comptroller(address(unitroller)),
            InterestRateModel(rateModel),
            1e18,
            "cToken A",
            "cTokenA",
            18,
            payable(address(this)),
            address(cErc20delegateA),
            "0x0"
        );
        cErc20DelegatorB = new CErc20Delegator(
            address(underlyingTokenB),
            Comptroller(address(unitroller)),
            InterestRateModel(rateModel),
            1e18,
            "cToken B",
            "cTokenB",
            18,
            payable(address(this)),
            address(cErc20delegateB),
            "0x0"
        );

        console.log("delegatorA", address(cErc20DelegatorA));
        console.log("delegatorB", address(cErc20DelegatorB));
    }

    function deployUnitroller() public {
        // deploy unitroller and add configuration
        unitroller = new Unitroller();
        uniTrollerProxy = Comptroller(address(unitroller));
        console.log("unitroller-proxy", address(uniTrollerProxy));
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        console.log("unitroller", address(unitroller));
    }

    function postDeploy() public {
        simpleOracle = new SimplePriceOracle();

        uniTrollerProxy._setPriceOracle(simpleOracle);
        simpleOracle.setUnderlyingPrice(
            CToken(address(cErc20DelegatorA)),
            1e18
        );
        simpleOracle.setUnderlyingPrice(
            CToken(address(cErc20DelegatorB)),
            100e18
        );

        uniTrollerProxy._setLiquidationIncentive(1e18);
        uniTrollerProxy._supportMarket(CToken(address(cErc20DelegatorA)));
        uniTrollerProxy._supportMarket(CToken(address(cErc20DelegatorB)));
        uniTrollerProxy._setCloseFactor(.5 * 1e18);
        uniTrollerProxy._setCollateralFactor(
            CToken(address(cErc20DelegatorB)),
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
