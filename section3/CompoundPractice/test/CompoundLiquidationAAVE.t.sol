import "forge-std/console.sol";
import "../src/CERC20Setup.sol";
import {Test} from "forge-std/Test.sol";

// import {IFlashLoanSimpleReceiver, IPoolAddressesProvider, IPool} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

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
    string constant MAINNET_RPC_URL = "https://eth.llamarpc.com";

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL, 17465000);
        setUpcErc20();
        console.log("address in CERC20Test", address(this));

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // give liquidity
        deal(USDCAddress, address(this), 2500 * 10 ** USDCDecimals);
        USDC.approve(address(CErc20DelegatorUSDC), 2500 * 10 ** USDCDecimals);
        CErc20DelegatorUSDC.mint(2500 * 10 ** USDCDecimals);

        console.log(
            "usdcBalance",
            USDC.balanceOf(address(CErc20DelegatorUSDC))
        );

        deal(UNIAddress, address(user1), 1000 * 10 ** UNIDecmials);
        vm.startPrank(user1);
        UNI.approve(address(CErc20DelegatorUNI), 1000 * 10 ** UNIDecmials);
        CErc20DelegatorUNI.mint(1000 * 10 ** UNIDecmials);
        address[] memory cTokens = new address[](2);
        cTokens[0] = address(CErc20DelegatorUNI);
        cTokens[1] = address(CErc20DelegatorUSDC);
        uint[] memory value = uniTrollerProxy.enterMarkets(cTokens);
        // (, uint accountToken, , ) = CErc20DelegatorUNI.getAccountSnapshot(
        //     address(user1)
        // );
        // console.log("accountToken user1", accountToken);
        CErc20DelegatorUSDC.borrow(2500 * 10 ** USDCDecimals);
        vm.stopPrank();
    }

    function executeOperation(
        address assets,
        uint256 amounts,
        uint256 premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // address checkerAddress = abi.decode(params, (address));
        // BalanceChecker checker = BalanceChecker(checkerAddress);
        // checker.checkBalance();
        // IERC20(USDC).approve(address(POOL()), premiums + amounts);
        // return true;
    }

    function test_aave_liquidation() public {}
}
