import "forge-std/console.sol";
import "../script/init.sol";

contract CERC20Test is MyScript {
    function setUp() public{
      run();
    }

    function test_deploy_success() public {
      console.log("test_deploy_success");
      console.log(address(comptroller));
    }

    
}
