import "forge-std/console.sol";
import "../script/init.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";

contract CERC20Test is MyScript {
    address user1;
    uint tokenADecimals; 
    function setUp() public {
      run();
      tokenADecimals = 10*10**underlyingTokenA.decimals();
      user1 = makeAddr("user1");
      // vm.deal(address(underlyingToken),address(user1), 1 ether);
     // uint result = cUSDC.mint(100* 10 ** USDC.decimals());

      vm.startPrank(user1);
      underlyingTokenA.mint(100*10**underlyingTokenA.decimals());
      vm.stopPrank();
    }

    function test_mint_and_redeem() public {
      vm.startPrank(user1);

      address[] memory cTokens = new address[](1);
      cTokens[0] = address(cErc20DelegatorA);

      (uint[] memory value) = uniTrollerProxy.enterMarkets(cTokens);
      
      underlyingTokenA.approve(address(cErc20DelegatorA), 100*10**underlyingTokenA.decimals());
      cErc20DelegatorA.mint(100*10 ** underlyingTokenA.decimals());
      console.log('underlyingToken decimals', underlyingTokenA.decimals());
      console.log('cToken balance before redeem',cErc20DelegatorA.balanceOf(address(user1)));
      cErc20DelegatorA.redeem(100*10 ** cErc20DelegatorA.decimals());
      console.log('cToken balance after redeem', cErc20DelegatorA.balanceOf(address(user1)));
    }
    
    
}
