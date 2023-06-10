import "forge-std/console.sol";
import "../script/init.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";

contract CERC20Test is MyScript {
    address user1;
    function setUp() public {
      run();

      user1 = makeAddr("user1");
      // vm.deal(address(underlyingToken),address(user1), 1 ether);
     // uint result = cUSDC.mint(100* 10 ** USDC.decimals());

      vm.startPrank(user1);
      underlyingToken.mint(100*10**underlyingToken.decimals());
      vm.stopPrank();
    }

    function test_deploy_success() public {
      vm.startPrank(user1);

      address[] memory cTokens = new address[](1);
      cTokens[0] = address(delegator);

      (uint[] memory value) = uniTrollerProxy.enterMarkets(cTokens);

      underlyingToken.approve(address(delegator), 10*10**underlyingToken.decimals());
      delegator.mint(10*10 ** underlyingToken.decimals());
      console.log('underlyingToken decimals', underlyingToken.decimals());
      console.log('underlyingToken balance', underlyingToken.balanceOf(address(user1)));
      // delegator.reedem(10*10 ** underlyingToken.decimals());
    }

    
}
