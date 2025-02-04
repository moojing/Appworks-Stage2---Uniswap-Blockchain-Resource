// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import  "forge-std/console.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";
// This is a pracitce contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {
    struct CallbackData {
        address borrowPool;
        address targetSwapPool;
        address borrowToken;
        address debtToken;
        uint256 borrowAmount;
        uint256 debtAmount;
        uint256 debtAmountOut;
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(sender == address(this), "Sender must be this contract");
        require(amount0 > 0 || amount1 > 0, "amount0 or amount1 must be greater than 0");
        // For Method 1 
        // // 3. decode callback data
        // CallbackData memory callbackData = abi.decode(data, (CallbackData));
        // // 4. swap WETH to USDC'
        // IERC20( callbackData.borrowToken ).transfer( callbackData.targetSwapPool, callbackData.borrowAmount );
        // IUniswapV2Pair(callbackData.targetSwapPool).swap( 0,callbackData.debtAmountOut , address(this), "");
        // // 5. repay USDC to lower price pool
        // IERC20(callbackData.debtToken).transfer(callbackData.borrowPool, callbackData.debtAmount);

        // For Method 2
        // 3. decode callback data
        CallbackData memory callbackData = abi.decode(data, (CallbackData));
        // 4. swap USDC to WETH 
        IERC20(callbackData.borrowToken).transfer( callbackData.targetSwapPool, callbackData.borrowAmount );
        IUniswapV2Pair(callbackData.targetSwapPool).swap( callbackData.debtAmountOut ,0, address(this), "");
        // 5. repay USDC to lower price pool
        IERC20(callbackData.debtToken).transfer(callbackData.borrowPool, callbackData.debtAmount);
        // 6. swap WETH For ETH 
        IERC20(callbackData.debtToken).transfer( callbackData.targetSwapPool, callbackData.borrowAmount );
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool
    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        // 1. finish callbackData
        // 2. flash swap (borrow WETH from lower price pool)
        CallbackData memory callbackData;
        callbackData.borrowToken = IUniswapV2Pair(priceLowerPool).token0();
        callbackData.debtToken = IUniswapV2Pair(priceLowerPool).token1();
        callbackData.borrowPool = priceLowerPool;
        callbackData.targetSwapPool = priceHigherPool;
        callbackData.borrowAmount = borrowETH;
        // 因為是計算 ETH 借出後，需要多少 usdc 進去才能維持 k 值，所以記得要用 getAmountIn
        callbackData.debtAmount = _getAmountIn(
            borrowETH, 
            IERC20(callbackData.debtToken).balanceOf(priceLowerPool),
            IERC20(callbackData.borrowToken).balanceOf(priceLowerPool)
        );
        // 這邊的 debtAmountOut 則是用來表示把借出來的 ETH 丟給 higher pool 之後，可以換到多少的 usdc ，所以用 getAmountOut
        callbackData.debtAmountOut = _getAmountOut(
            borrowETH, 
            IERC20(callbackData.borrowToken).balanceOf(priceHigherPool),
            IERC20(callbackData.debtToken).balanceOf(priceHigherPool)
        );
        
        // Uncomment next line when you do the homework
        IUniswapV2Pair(priceLowerPool).swap(borrowETH, 0, address(this), abi.encode(callbackData));
    }

        function arbitrage2(address priceLowerPool, address priceHigherPool, uint256 borrowUSDC) external {
        // 1. finish callbackData
        // 2. flash swap (borrow WETH from lower price pool)
        CallbackData memory callbackData;
        callbackData.borrowToken = IUniswapV2Pair(priceLowerPool).token1();
        callbackData.debtToken = IUniswapV2Pair(priceLowerPool).token0();
        callbackData.borrowPool = priceHigherPool;
        callbackData.targetSwapPool = priceLowerPool;
        callbackData.borrowAmount = borrowUSDC;
        // 因為是計算 USDC 借出後，需要多少 ETH 進去才能維持 k 值，所以記得要用 getAmountIn
        callbackData.debtAmount = _getAmountIn(
            borrowUSDC, 
            IERC20(callbackData.debtToken).balanceOf(priceHigherPool),
            IERC20(callbackData.borrowToken).balanceOf(priceHigherPool)
        );
        // 這邊的 debtAmountOut 則是用來表示把借出來的 USDC 丟給 lower pool 之後，可以換到多少的  ETH，所以用 getAmountOut
        callbackData.debtAmountOut = _getAmountOut(
            borrowUSDC, 
            IERC20(callbackData.borrowToken).balanceOf(priceLowerPool),
            IERC20(callbackData.debtToken).balanceOf(priceLowerPool)
        );
        
        // Uncomment next line when you do the homework
        IUniswapV2Pair(priceHigherPool).swap(0, borrowUSDC, address(this), abi.encode(callbackData));
    }



    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
