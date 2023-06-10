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
      underlyingTokenB.mint(1*10**underlyingTokenB.decimals());
      
      address[] memory cTokens = new address[](2);
      cTokens[0] = address(cErc20DelegatorA);
      cTokens[1] = address(cErc20DelegatorB);
      (uint[] memory value) = uniTrollerProxy.enterMarkets(cTokens);

      vm.stopPrank();
    }

    function test_mint_and_redeem() public {
      vm.startPrank(user1);
      
      underlyingTokenA.approve(address(cErc20DelegatorA), 100*10**underlyingTokenA.decimals());
      cErc20DelegatorA.mint(100*10 ** underlyingTokenA.decimals());
      console.log('underlyingToken decimals', underlyingTokenA.decimals());
      console.log('cToken balance before redeem',cErc20DelegatorA.balanceOf(address(user1)));
      cErc20DelegatorA.redeem(100*10 ** cErc20DelegatorA.decimals());
      console.log('cToken balance after redeem', cErc20DelegatorA.balanceOf(address(user1)));
    }
    
    
    function test_borrow_and_repay() public {
      vm.startPrank(user1);
      underlyingTokenB.approve(address(cErc20DelegatorB), 1*10**underlyingTokenB.decimals());
      underlyingTokenA.approve(address(cErc20DelegatorA), 150*10**underlyingTokenA.decimals());
      cErc20DelegatorB.mint(1*10 ** underlyingTokenB.decimals());
      cErc20DelegatorA.mint(100*10 ** underlyingTokenA.decimals());
    
      cErc20DelegatorA.borrow(50 * 10**underlyingTokenA.decimals());
      (,,uint accountBorrow,) = cErc20DelegatorA.getAccountSnapshot(address(user1));
      console.log('accountBorrow',accountBorrow);
      cErc20DelegatorA.repayBorrow(50 * 10**underlyingTokenA.decimals());
      (,,uint accountBorrowAfter,) = cErc20DelegatorA.getAccountSnapshot(address(user1));
      console.log('accountBorrow After repay',accountBorrowAfter);
    }
}
