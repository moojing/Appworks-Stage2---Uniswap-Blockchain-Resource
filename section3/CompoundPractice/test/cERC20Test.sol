import "forge-std/console.sol";
import "../script/init.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";

contract CERC20Test is MyScript {
    address user1;
    address user2;
    address admin;
    uint256 deployerPrivateKey = vm.envUint("SCRIPT_PRIVATE_KEY");

    function setUp() public {
      run();
    
      admin = vm.addr(deployerPrivateKey);
      user1 = makeAddr("user1");
      user2 = makeAddr("user2");

      vm.startPrank(user2);
      underlyingTokenA.mint(150*10**underlyingTokenA.decimals());
      vm.stopPrank();

      vm.startPrank(user1);
      underlyingTokenA.mint(100*10**underlyingTokenA.decimals());
      underlyingTokenB.mint(1*10**underlyingTokenB.decimals());
      
      address[] memory cTokens = new address[](2);
      cTokens[0] = address(cErc20DelegatorB);
      // cTokens[1] = address(cErc20DelegatorB);
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
      vm.startPrank(user2);
      underlyingTokenA.approve(address(cErc20DelegatorA), 150*10**underlyingTokenA.decimals());
      cErc20DelegatorA.mint(100*10 ** underlyingTokenA.decimals());
      vm.stopPrank();

      vm.startPrank(user1);
      // 抵押一顆 tokenB
      underlyingTokenB.approve(address(cErc20DelegatorB), 1*10**underlyingTokenB.decimals());
      cErc20DelegatorB.mint(1*10 ** underlyingTokenB.decimals());
    
      cErc20DelegatorA.borrow(50 * 10**underlyingTokenA.decimals());
      (,,uint accountBorrow,) = cErc20DelegatorA.getAccountSnapshot(address(user1));
      console.log('accountBorrow',accountBorrow);
      // user1 還款
      // cErc20DelegatorA.repayBorrow(50 * 10**underlyingTokenA.decimals());
      // (,,uint accountBorrowAfter,) = cErc20DelegatorA.getAccountSnapshot(address(user1));
      // console.log('accountBorrow After repay',accountBorrowAfter);
      vm.stopPrank();
      
      vm.startPrank(admin);
      uniTrollerProxy._setCollateralFactor(CToken(address(cErc20DelegatorB)),.4 * 1e18);
      vm.stopPrank();

      vm.startPrank(user2);
      cErc20DelegatorA.liquidateBorrow(user1,22*10**underlyingTokenA.decimals(),cErc20DelegatorB);
      vm.stopPrank();

    }
}
