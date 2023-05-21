// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    uint256 private _reserveA; // uses single storage slot, accessible via getReserves
    uint256 private _reserveB;
    address private _tokenA;
    address private _tokenB;

    using Math for uint256;

    constructor(address tokenA, address tokenB) ERC20("simpleSwapLiquidToken", "SLP") {
        require(isContract(tokenA), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(isContract(tokenB), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(tokenB != tokenA, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");

        (address addressA, address addressB) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        _tokenA = addressA;
        _tokenB = addressB;
    }

    function isContract(address addr) internal returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        return 0;
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
        amountA = amountAIn;
        amountB = amountBIn;
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // amountA = balance0.sub(_reserveA);
        // amountB = balance1.sub(_reserveB);

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(SafeMath.mul(amountAIn, amountBIn));
        } else {
            liquidity = Math.min(
                Math.mulDiv(amountAIn, _totalSupply, reserveA),
                Math.mulDiv(amountBIn, _totalSupply, reserveB)
            );
        }

        _reserveA = reserveA + amountAIn;
        _reserveB = reserveB + amountBIn;

        _mint(msg.sender, liquidity);
        emit AddLiquidity(address(msg.sender), amountAIn, amountBIn, liquidity);
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

        uint balanceA = tokenA.balanceOf(msg.sender);
        uint balanceB = tokenB.balanceOf(msg.sender);
        amountA = SafeMath.mul(liquidity, balanceA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = SafeMath.mul(liquidity, balanceB) / _totalSupply;

        _burn(address(this), liquidity);

        tokenA.transferFrom(address(this), msg.sender, amountA);
        tokenB.transferFrom(address(this), msg.sender, amountB);
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
