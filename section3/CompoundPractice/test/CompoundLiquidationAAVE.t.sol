import "forge-std/console.sol";
import "../src/CERC20Setup.sol";

// import {Comptroller} from "compound-protocol/contracts/Comptroller.sol";

contract CompoundLiquidationAAVE is CERC20Setup {
    address user1;
    address user2;
    address admin;
    uint mainnetFork;
    string constant MAINNET_RPC_URL = "https://eth.llamarpc.com";

    function setUp() public {
        setUpcErc20();
        vm.createSelectFork(MAINNET_RPC_URL, 17465000);
        console.log("address in CERC20Test", address(this));

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(user2);
        underlyingTokenA.mint(150 * 10 ** underlyingTokenA.decimals());
        vm.stopPrank();

        vm.startPrank(user1);
        underlyingTokenA.mint(100 * 10 ** underlyingTokenA.decimals());
        underlyingTokenB.mint(1 * 10 ** underlyingTokenB.decimals());

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cErc20DelegatorB);
        uint[] memory value = uniTrollerProxy.enterMarkets(cTokens);

        vm.stopPrank();
    }

    function test_aave_liquidation() public {
        vm.rollFork(15815693);
    }
}
