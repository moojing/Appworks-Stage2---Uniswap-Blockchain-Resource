import "forge-std/console.sol";
import "../script/init.sol";

contract CERC20Test is MyScript {
    address user1;
    function setUp() public {
      user1 = makeAddr("user1");
      run();
      // vm.deal(address(underlyingToken),address(user1), 1 ether);
     // uint result = cUSDC.mint(100* 10 ** USDC.decimals());

      vm.startPrank(user1);
      underlyingToken.mint(100*10**underlyingToken.decimals());
      vm.stopPrank();
    }

    function test_deploy_success() public {
      console.log("test_deploy_success");
      console.log(address(comptroller));
      vm.startPrank(user1);
      // cErc20delegate
      underlyingToken.approve(address(cErc20delegate), 10*10**underlyingToken.decimals());
      delegator.mint(10 ** underlyingToken.decimals());
    }

    
}
