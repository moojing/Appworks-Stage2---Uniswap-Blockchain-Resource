import "forge-std/console.sol";
import "../src/CERC20Setup.sol";
import {Test} from "forge-std/Test.sol";
import {CToken} from "compound-protocol/contracts/CToken.sol";

import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract CompoundLiquidationAAVE is CERC20Setup, Test {
    address user1;
    address user2;
    address admin;
    uint mainnetFork;
    uint USDCDecimals = 6;
    uint UNIDecmials = 18;
    address public constant UNIAddress =
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address public constant USDCAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    string constant MAINNET_RPC_URL = "https://eth.llamarpc.com";

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL, 17465000);
        setUpcErc20();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // give liquidity
        deal(USDCAddress, address(this), 2500 * 10 ** USDCDecimals);
        USDC.approve(address(CErc20DelegatorUSDC), 2500 * 10 ** USDCDecimals);
        CErc20DelegatorUSDC.mint(2500 * 10 ** USDCDecimals);
        // mortgage UNI
        deal(UNIAddress, address(user1), 1000 * 10 ** UNIDecmials);
        vm.startPrank(user1);
        UNI.approve(address(CErc20DelegatorUNI), 1000 * 10 ** UNIDecmials);
        CErc20DelegatorUNI.mint(1000 * 10 ** UNIDecmials);
        //
        address[] memory cTokens = new address[](2);
        cTokens[0] = address(CErc20DelegatorUNI);
        uint[] memory value = uniTrollerProxy.enterMarkets(cTokens);
        // (, uint accountToken, , ) = CErc20DelegatorUNI.getAccountSnapshot(
        //     address(user1)
        // );
        // console.log("accountToken user1", accountToken);

        // borrow USDC
        CErc20DelegatorUSDC.borrow(2500 * 10 ** USDCDecimals);
        vm.stopPrank();
    }

    function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
        return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
    }

    function POOL() public view returns (IPool) {
        return IPool(ADDRESSES_PROVIDER().getPool());
    }

    function executeOperation(
        address assets,
        uint256 amounts,
        uint256 premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        console.log(
            "USDC balance after borrowing",
            USDC.balanceOf(address(this))
        );
        // liquidate USDC for cUNI
        USDC.approve(address(CErc20DelegatorUSDC), 1250 * 10 ** USDCDecimals);
        CErc20DelegatorUSDC.liquidateBorrow(
            user1,
            1250 * 10 ** USDCDecimals,
            CErc20DelegatorUNI
        );
        // redeem for UNI
        CErc20DelegatorUNI.redeem(CErc20DelegatorUNI.balanceOf(address(this)));
        console.log(
            "UNI balance after redeeming from cUNI",
            UNI.balanceOf(address(this))
        );

        // swap UNI for USDC

        // swap Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564
        ISwapRouter swapRouter = ISwapRouter(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );

        UNI.approve(address(swapRouter), UNI.balanceOf(address(this)));
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: UNIAddress,
                tokenOut: USDCAddress,
                fee: 3000, // 0.3%
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: UNI.balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        // The call to `exactInputSingle` executes the swap.
        uint256 amountOutUSDC = swapRouter.exactInputSingle(swapParams);
        console.log("USDC amountOut swap from uniswap", amountOutUSDC);
        console.log("premiums + amounts", premiums + amounts);

        IERC20(USDC).approve(address(POOL()), premiums + amounts);
        console.log("profits =", amountOutUSDC - premiums - amounts);
        return true;
    }

    function test_aave_liquidation() public {
        simpleOracle.setUnderlyingPrice(
            CToken(address(CErc20DelegatorUNI)),
            4 * 1e18
        );

        POOL().flashLoanSimple(
            address(this),
            address(USDC),
            1250 * 10 ** 6,
            abi.encode(address(this)),
            0
        );
    }
}
