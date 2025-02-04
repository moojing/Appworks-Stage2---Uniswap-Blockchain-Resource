// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import { IUniswapV2Router01 } from "v2-periphery/interfaces/IUniswapV2Router01.sol";
import { IUniswapV2Factory } from "v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { TestERC20 } from "../contracts/test/TestERC20.sol";

contract UniswapV2PracticeTest is Test {
    IUniswapV2Router01 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    TestERC20 public testUSDC;
    IUniswapV2Pair public WETHTestUSDCPair;
    address public taker = makeAddr("Taker");
    address public maker = makeAddr("Maker");

    function setUp() public {
        // fork block
        vm.createSelectFork("mainnet", 17254242);

        // deploy test USDC
        testUSDC = _create_erc20("Test USDC", "USDC", 6);

        // mint 100 ETH, 10000 USDC to maker
        deal(maker, 100 ether);
        testUSDC.mint(maker, 10000 * 10 ** testUSDC.decimals());

        // mint 1 ETH to taker
        deal(taker, 100 ether);

        // create ETH/USDC pair
        WETHTestUSDCPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.createPair(address(WETH9), address(testUSDC)));

        vm.label(address(UNISWAP_V2_ROUTER), "UNISWAP_V2_ROUTER");
        vm.label(address(UNISWAP_V2_FACTORY), "UNISWAP_V2_FACTORY");
        vm.label(address(WETH9), "WETH9");
        vm.label(address(testUSDC), "TestUSDC");
    }

    // # Practice 1: maker add liquidity (100 ETH, 10000 USDC)
    function test_maker_addLiquidityETH() public {
        // Implement here
        vm.startPrank(maker);
        testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: 100 ether }(
            address(testUSDC),
            10000 * 10 ** testUSDC.decimals(),
            100, //  can be 0
            1 ether, //  can be 0
            maker,
            block.timestamp + 100000
        );
        vm.stopPrank();

        // Checking
        IUniswapV2Pair wethUsdcPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.getPair(address(WETH9), address(testUSDC)));
        (uint112 reserve0, uint112 reserve1, ) = wethUsdcPair.getReserves();
        console2.log(reserve0);
        console2.log(reserve1);
        assertEq(reserve0, 10000 * 10 ** testUSDC.decimals());
        assertEq(reserve1, 100 ether);
    }

    // # Practice 2: taker swap exact 100 ETH for testUSDC
    function test_taker_swapExactETHForTokens() public {
        // add Liquidity
        vm.startPrank(maker);
        testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: 100 ether }(
            address(testUSDC),
            10000 * 10 ** testUSDC.decimals(),
            100, //  can be 0
            1 ether, //  can be 0
            maker,
            block.timestamp + 100000
        );
        vm.stopPrank();
        // Impelement here
        vm.startPrank(taker);
        address[] memory path = new address[](2);
        path[0] = address(WETH9);
        path[1] = address(address(testUSDC));
        UNISWAP_V2_ROUTER.swapExactETHForTokens{ value: 100 ether }(0, path, taker, block.timestamp + 100000);
        vm.stopPrank();
        // Checking
        // # Disscussion 1: discuss why 4992488733 ?
        // initial  10000 * 100
        // (100 + 100* 0.997) * 10000 - x' = 10000 * 100 =
        // x' = 4,992.4887330996
        assertEq(testUSDC.balanceOf(taker), 4992488733);
        assertEq(taker.balance, 0);
    }

    // # Practice 3: taker swap exact 10000 USDC for ETH
    function test_taker_swapExactTokensForETH() public {
        testUSDC.mint(taker, 10000 * 10 ** testUSDC.decimals());
        vm.startPrank(maker);
        testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: 100 ether }(
            address(testUSDC),
            10000 * 10 ** testUSDC.decimals(),
            100, //  can be 0
            1 ether, //  can be 0
            maker,
            block.timestamp + 100000
        );
        vm.stopPrank();
        // Impelement here
        vm.startPrank(taker);

        testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());
        address[] memory path = new address[](2);
        path[0] = address(address(testUSDC));
        path[1] = address(WETH9);
        UNISWAP_V2_ROUTER.swapExactTokensForETH(
            10000 * 10 ** testUSDC.decimals(),
            0,
            path,
            taker,
            block.timestamp + 100000
        );
        vm.stopPrank();

        // Checking
        // original k = 10000 * 100
        // 1000000 = (10000 + 10000 * 0.997) * (100  - x )
        // 1000000 / (10000 + 10000*0.997) - 100  = x = 49.92489
        // # Disscussion 2: original balance is 100 ether, so delta is 49924887330996494742, but why 49924887330996494742 ?
        assertEq(testUSDC.balanceOf(taker), 0);
        assertEq(taker.balance, 149924887330996494742);
    }

    // # Practice 4: maker remove all liquidity
    function test_maker_removeLiquidityETH() public {
        vm.startPrank(maker);
        testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: 100 ether }(
            address(testUSDC),
            10000 * 10 ** testUSDC.decimals(),
            100, //  can be 0
            1 ether, //  can be 0
            maker,
            block.timestamp + 100000
        );
        vm.stopPrank();
        // Implement here

        vm.startPrank(maker);
        WETHTestUSDCPair.approve(address(UNISWAP_V2_ROUTER), WETHTestUSDCPair.balanceOf(maker));
        // testUSDC.approve(address(UNISWAP_V2_ROUTER), 10000 * 10 ** testUSDC.decimals());

        UNISWAP_V2_ROUTER.removeLiquidityETH(
            address(testUSDC),
            WETHTestUSDCPair.balanceOf(maker),
            0,
            0,
            maker,
            block.timestamp + 100000
        );
        vm.stopPrank();

        // Checking
        IUniswapV2Pair wethUsdcPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.getPair(address(WETH9), address(testUSDC)));
        (uint112 reserve0, uint112 reserve1, ) = wethUsdcPair.getReserves();
        assertEq(reserve0, 1);
        assertEq(reserve1, 100000000);
    }

    function _create_erc20(string memory name, string memory symbol, uint8 decimals) internal returns (TestERC20) {
        TestERC20 testERC20 = new TestERC20(name, symbol, decimals);
        return testERC20;
    }
}
