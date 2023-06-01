// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20 } from "compound-protocol/contracts/CErc20.sol";
import "test/helper/CompoundPracticeSetUp.sol";
import "forge-std/console.sol";

interface IBorrower {
  function borrow() external;
}

contract CompoundPracticeTest is CompoundPracticeSetUp {
  EIP20Interface public USDC = EIP20Interface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
  address public user;
  string constant MAINNET_RPC_URL = "https://eth.llamarpc.com";

  IBorrower public borrower;

  uint256 mainnetFork;

  function setUp() public override {
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    super.setUp();
    vm.roll(block.number); 
    // vm.warp(block.timestamp); 
    // Deployed in CompoundPracticeSetUp helper
    borrower = IBorrower(borrowerAddress);

    user = makeAddr("User");  

    uint256 initialBalance = 10000 * 10 ** USDC.decimals();
    deal(address(USDC), user, initialBalance);

    vm.label(address(cUSDC), "cUSDC");
    vm.label(borrowerAddress, "Borrower");
  }

  function test_compound_mint_interest() public {
    vm.startPrank(user); 
    // TODO: 1. Mint some cUSDC with USDC
    USDC.approve(address(cUSDC), 100 * 10 ** USDC.decimals());
    uint result = cUSDC.mint(100* 10 ** USDC.decimals());
    require(result == 0, "Mint failed");
    // TODO: 2. Modify block state to generate interest
    // vm.warp(block.timestamp + 1 days);
    vm.roll(block.number+100); 
    // TODO: 3. Redeem and check the redeemed amount
    cUSDC.redeem(cUSDC.balanceOf(user));
    console.log('balance',USDC.balanceOf(user));
  }

  function test_compound_mint_interest_with_borrower() public {
    vm.startPrank(user); 
    // TODO: 1. Mint some cUSDC with USDC
    USDC.approve(address(cUSDC), 100 * 10 ** USDC.decimals());
    uint result = cUSDC.mint(100* 10 ** USDC.decimals());
    require(result == 0, "Mint failed");
    // 2. Borrower.borrow() will borrow some USDC
    borrower.borrow();

    // TODO: 3. Modify block state to generate interest

    vm.roll(block.number+100); 
    // TODO: 4. Redeem and check the redeemed amount
    cUSDC.redeem(cUSDC.balanceOf(user));
    console.log('balance',USDC.balanceOf(user));
  }
}
