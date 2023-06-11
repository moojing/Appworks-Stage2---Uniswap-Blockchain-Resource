import "forge-std/console.sol";
import "../script/init.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { GovernorBravoDelegate } from '../contract/BravoDelegateCustom.sol';

contract CERC20Test is MyScript {
    address user1;
    address user2;
    address admin;
    function setUp() public {
      run();
    
      console.log('address in CERC20Test', address(this));

      admin = vm.addr(deployerPrivateKey);
      user1 = makeAddr("user1");
      user2 = makeAddr("user2");
      console.log('admin in test',admin);

      vm.startPrank(admin);
      console.log('admin comp balance', compToken.balanceOf(address(admin)));
      compToken.transfer(user1, 600*10**compToken.decimals());     
      compToken.transfer(user2, 600*10**compToken.decimals());     
      // 這行不會過，要先 發交易執行 executeTransaction 來設定 pending admin
      // GovernorBravoDelegate(address(bravoDelegator))._initiate(address(alpha)); 
      
      console.log('user1 comp balance', compToken.balanceOf(address(user1)));
      console.log('user2 comp balance', compToken.balanceOf(address(user2)));
      
      vm.stopPrank();

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
      // Case: user1 還款
      // cErc20DelegatorA.repayBorrow(50 * 10**underlyingTokenA.decimals());
      // (,,uint accountBorrowAfter,) = cErc20DelegatorA.getAccountSnapshot(address(user1));
      // console.log('accountBorrow After repay',accountBorrowAfter);
      vm.stopPrank();
      
      // Case: 調整 collateral factor 導致清算
      // vm.startPrank(admin);
      // uniTrollerProxy._setCollateralFactor(CToken(address(cErc20DelegatorB)),.4 * 1e18);
      // vm.stopPrank();
      //
      // vm.startPrank(user2);
      // cErc20DelegatorA.liquidateBorrow(user1,25*10**underlyingTokenA.decimals(),cErc20DelegatorB);
      // vm.stopPrank();

      // Case: 調整 underlying price 導致清算
      vm.startPrank(admin);
      simpleOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorB)), 49e18);
      vm.stopPrank();

      vm.startPrank(user2);
      cErc20DelegatorA.liquidateBorrow(user1,25*10**underlyingTokenA.decimals(),cErc20DelegatorB);
      vm.stopPrank();
    }

    function test_comp_vote() public {
      // delegate 給 user2
      vm.startPrank(user1);
      compToken.delegate(address(user2));
      vm.stopPrank();
      
      //沒有做完，沒辦法正常發 propose ，TimeLock需要一些設定
      vm.startPrank(user2);
        compToken.delegate(address(user2));
        address[] memory tos = new address[](1);
        uint[] memory values = new uint[](1);
        string[] memory sigs = new string[](1);
        bytes[] memory calldatas = new bytes[](1);

        tos[0] = address(uniTrollerProxy);
        values[0] = 0;
        sigs[0] = "_setLiquidationIncentive(uint256)";
        calldatas[0] = abi.encode(7*10**17);

        // console.logBytes(abi.encode(7*10**17));
        // 需要先 initiate        
        // GovernorBravoDelegate(address(bravoDelegator)).propose( 
        //            tos, 
        //            values, 
        //            sigs, 
        //            calldatas, 
        //            "liquidation incentive proposal");             
      vm.stopPrank();

      // uint vote1 = compToken.getCurrentVotes(address(user1));
      // uint vote2 = compToken.getCurrentVotes(address(user2));
      // console.log('vote user1 ',vote1);
      // console.log('vote user2 ',vote2);
    }
}
