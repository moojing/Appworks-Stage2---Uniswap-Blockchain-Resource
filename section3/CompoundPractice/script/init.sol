
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { WhitePaperInterestRateModel } from "compound-protocol/contracts/WhitePaperInterestRateModel.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { CToken } from "compound-protocol/contracts/CToken.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { InterestRateModel } from "compound-protocol/contracts/InterestRateModel.sol";
import { SimplePriceOracle } from "compound-protocol/contracts/SimplePriceOracle.sol";
// import { Comp } from "compound-protocol/contracts/Governance/Comp.sol";

contract UnderlyingToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}
    
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

contract MyScript is Script {
    Comptroller comptroller;
    CErc20Delegator delegator;
    CErc20Delegate cErc20delegate;
    UnderlyingToken underlyingToken;
    WhitePaperInterestRateModel rateModel;
    Unitroller unitroller;
    Comptroller uniTrollerProxy;   
    
    function preDeploy() public {
        comptroller = new Comptroller();
        underlyingToken = new UnderlyingToken("underLying token", "UDT");
        rateModel = new WhitePaperInterestRateModel(0,0);
        cErc20delegate = new CErc20Delegate();
    } 

    function deployComptroller() public {
        // deploy underlying token 
        // deploy CErc20Delegate
        // datectory deploy CErc20Delegator
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
        delegator = new CErc20Delegator(
            address(underlyingToken),
            // ????
            Comptroller(address(unitroller)),
            InterestRateModel(rateModel),
            1e18,
            "cToken",
            "cToken",
            18,
            payable(address(this)),
            address(cErc20delegate),
            "0x0"
        );
        console.log('delegator', address(delegator));
    }

    function deployUnitroller() public {
         // deploy unitroller and add configuration
        unitroller = new Unitroller();
        uniTrollerProxy = Comptroller(address(unitroller));
        console.log('unitroller-proxy', address(uniTrollerProxy));
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        
        console.log('unitroller',address(unitroller));
    }

    function postDeploy () public {
        
        SimplePriceOracle simpleOracle = new SimplePriceOracle(); 
        uniTrollerProxy._setLiquidationIncentive(1e18);
        uniTrollerProxy._supportMarket(CToken(address(delegator)));
        uniTrollerProxy._setCloseFactor(.051 * 1e18);
        uniTrollerProxy._setPriceOracle(simpleOracle);
        simpleOracle.setUnderlyingPrice(CToken(address(delegator)), 1e18);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("SCRIPT_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        preDeploy();
        deployUnitroller();
        deployComptroller();
        postDeploy();

        vm.stopBroadcast();
    }
}
