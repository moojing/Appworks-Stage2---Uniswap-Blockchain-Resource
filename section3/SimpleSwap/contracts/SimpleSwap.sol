// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { console2 } from "forge-std/console2.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    uint256 private _reserveA; // uses single storage slot, accessible via getReserves
    uint256 private _reserveB;
    address private _tokenA;
    address private _tokenB;

    using Math for uint256;
    using SafeMath for uint256;

    constructor(address tokenA, address tokenB) ERC20("simpleSwapLiquidToken", "SLP") {
        require(isContract(tokenA), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(isContract(tokenB), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(tokenB != tokenA, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");

        (address addressA, address addressB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        _tokenA = addressA;
        _tokenB = addressB;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function quote(uint amount1, uint reserve1, uint reserve2) internal pure returns (uint amount2) {
        require(amount1 > 0, "SimpleSwap: INSUFFICIENT_AMOUNT");
        require(reserve1 > 0 && reserve2 > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");
        amount2 = amount1.mul(reserve2) / reserve1;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        //  BOut = reserveB - ((reserveA * reserveB - 1) / (reserveA + AIn) + 1) --> this method will have some error
        amountOut = (reserveOut * amountIn) / (reserveIn + amountIn);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(tokenIn == _tokenA || tokenIn == _tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == _tokenA || tokenOut == _tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");

        (uint256 reserveIn, uint256 reserveOut) = tokenIn == _tokenA ? (_reserveA, _reserveB) : (_reserveB, _reserveA);

        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        IERC20(tokenOut).approve(address(this), amountOut);
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transferFrom(address(this), msg.sender, amountOut);
        _updateReserve();
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Add liquidity to the pool
    /// @param amountAIn The amount of tokenA to add
    /// @param amountBIn The amount of tokenB to add
    /// @return amountA The actually amount of tokenA added
    /// @return amountB The actually amount of tokenB added
    /// @return liquidity The amount of liquidity minted
    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (amountAIn == 0 || amountBIn == 0) revert("SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        (uint256 reserveA, uint256 reserveB) = getReserves();
        uint _totalSupply = totalSupply();
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);

        // amountA = balance0.sub(_reserveA);
        // amountB = balance1.sub(_reserveB);

        if (_totalSupply == 0) {
            tokenA.transferFrom(msg.sender, address(this), amountAIn);
            tokenB.transferFrom(msg.sender, address(this), amountBIn);

            liquidity = Math.sqrt(SafeMath.mul(amountAIn, amountBIn));
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            uint optimalA = quote(amountBIn, reserveB, reserveA);
            uint optimalB = quote(amountAIn, reserveA, reserveB);

            // 如果用 amountBIn 得出的 optimalA 比原來的 amountAin 還要小，表示 amountAIn 有多餘的值，應該使用 optimalA + amountBIn
            // 反過來也是一樣
            if (amountAIn >= optimalA) {
                (amountA, amountB) = (optimalA, amountBIn);
            } else if (amountBIn >= optimalB) {
                (amountA, amountB) = (amountAIn, optimalB);
            } else {
                (amountA, amountB) = (amountAIn, amountBIn);
            }

            tokenA.transferFrom(msg.sender, address(this), amountA);
            tokenB.transferFrom(msg.sender, address(this), amountB);

            liquidity = Math.min(
                Math.mulDiv(amountA, _totalSupply, reserveA),
                Math.mulDiv(amountB, _totalSupply, reserveB)
            );
        }

        _reserveA = reserveA + amountA;
        _reserveB = reserveB + amountB;

        _mint(msg.sender, liquidity);
        emit AddLiquidity(address(msg.sender), amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    /// @param liquidity The amount of liquidity to remove
    /// @return amountA The amount of tokenA received
    /// @return amountB The amount of tokenB received
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        if (liquidity == 0) revert("SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        uint _totalSupply = totalSupply();
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);

        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));
        amountA = SafeMath.mul(liquidity, balanceA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = SafeMath.mul(liquidity, balanceB) / _totalSupply;

        emit Transfer(address(this), address(0), liquidity);
        _burn(msg.sender, liquidity);

        tokenA.approve(address(this), amountA);
        tokenB.approve(address(this), amountB);

        tokenA.transferFrom(address(this), msg.sender, amountA);
        tokenB.transferFrom(address(this), msg.sender, amountB);

        _updateReserve();
        emit RemoveLiquidity(address(msg.sender), amountA, amountB, liquidity);
    }

    function _updateReserve() internal {
        uint balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint balanceB = IERC20(_tokenB).balanceOf(address(this));
        _reserveA = balanceA;
        _reserveB = balanceB;
    }

    /// @notice Get the reserves of the pool
    /// @return reserveA The reserve of tokenA
    /// @return reserveB The reserve of tokenB
    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    /// @notice Get the address of tokenA
    /// @return tokenA The address of tokenA
    function getTokenA() external view returns (address tokenA) {
        tokenA = _tokenA;
    }

    /// @notice Get the address of tokenB
    /// @return tokenB The address of tokenB
    function getTokenB() external view returns (address tokenB) {
        tokenB = _tokenB;
    }
}
