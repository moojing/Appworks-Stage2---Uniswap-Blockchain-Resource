pragma solidity 0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IUniswapV2Callee} from "v2-core/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {CErc20} from "compound-protocol/contracts/CErc20.sol";
import "forge-std/console.sol";

contract FlashSwapLiquidate is IUniswapV2Callee {
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    CErc20 public cDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    IUniswapV2Router02 public router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct CallbackData {
        address borrower;
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        address pool = IUniswapV2Factory(factory).getPair(
            address(DAI),
            address(USDC)
        );
        CallbackData memory callbackData = abi.decode(data, (CallbackData));
        // console.log('borrower', callbackData.borrower);
        // console.log('amount1',amount1);
        //
        USDC.approve(address(cUSDC), amount1);
        cUSDC.liquidateBorrow(callbackData.borrower, amount1,cDAI);
        // console.log('cDAI balance ', cDAI.balanceOf(address(this)));
        cDAI.redeem(cDAI.balanceOf(address(this)));
        // console.log('DAI balance ', DAI.balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(USDC);
        uint256 repayUniswapAmount = router.getAmountsIn(amount1, path)[0];
        console.log(repayUniswapAmount);
        DAI.transfer(pool, repayUniswapAmount);
    }

    function liquidate(address borrower, uint256 amountOut) external {
        console.log("amountOut", amountOut );
        address pool = IUniswapV2Factory(factory).getPair(
            address(DAI),
            address(USDC)
        );
        IUniswapV2Pair(pool).swap(
            0,
            amountOut,
            address(this),
            abi.encode(
                CallbackData({
                    // DAI
                    borrower: borrower
                })
            )
        );
    }
}
