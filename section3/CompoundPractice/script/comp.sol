import "forge-std/Script.sol";
import { Comp } from "compound-protocol/contracts/Governance/Comp.sol";
// import { Timelock } from "compound-protocol/contracts/Timelock.sol";
import { Timelock } from '../contract/TimeLockCustom.sol';
import { GovernorBravoDelegate } from '../contract/BravoDelegateCustom.sol';
import { GovernorBravoDelegator } from "compound-protocol/contracts/Governance/GovernorBravoDelegator.sol";
import { GovernorAlpha } from "compound-protocol/contracts/Governance/GovernorAlpha.sol";


contract CompScript {
  address deployerAddress;
  Timelock timelock;
  GovernorAlpha public alpha;
  Comp public  compToken;
  GovernorBravoDelegate bravoDelegate;
  GovernorBravoDelegator public bravoDelegator;
 

  function deploy () public {
  }
 
  constructor(address admin) public {
       deployerAddress = admin;
       compToken = new Comp(deployerAddress);
       timelock = new Timelock(deployerAddress, 120 seconds);
       timelock.setPendingAdmin(admin);
       bravoDelegate = new GovernorBravoDelegate();
       //  	 constructor(
	     // address timelock_,
	     // address comp_,
	     // address admin_,
       //   address implementation_,
       //   uint votingPeriod_,
       //   uint votingDelay_,
       //    uint proposalThreshold_) 
      bravoDelegator = new GovernorBravoDelegator(
        address(timelock),
        address(compToken),
        deployerAddress,
        address(bravoDelegate),
        300,
        60,
        1000e18
      );
      
      alpha = new GovernorAlpha(address(timelock), address(compToken),admin);

  }
}
