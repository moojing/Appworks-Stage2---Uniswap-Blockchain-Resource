import "forge-std/Script.sol";
import { Comp } from "compound-protocol/contracts/Governance/Comp.sol";
import { Timelock } from "compound-protocol/contracts/Timelock.sol";
import { GovernorBravoDelegator } from "compound-protocol/contracts/Governance/GovernorBravoDelegator.sol";
import { GovernorBravoDelegate } from "compound-protocol/contracts/Governance/GovernorBravoDelegate.sol";

contract CompScript {
  address deployerAddress;
  Timelock timelock;
  Comp compToken;
  GovernorBravoDelegate bravoDelegate;
  GovernorBravoDelegator bravoDelegator;
 

  function deploy () public {
  }
 
  constructor(address admin) public {
       deployerAddress = admin;
       compToken = new Comp(deployerAddress);
       timelock = new Timelock(deployerAddress, 60 seconds);
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
        timelock,
        address(compToken),
        deployerAddress,
        address(bravoDelegate),
        300,
        60,
        500e18
      );
  }
}
