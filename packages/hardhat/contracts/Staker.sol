// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 74 hours;

  bool public openForWithdraw = false;

  event Stake(address sender, uint256 amount);

  mapping( address => uint256) public balances;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier afterDeadline() {
    require(block.timestamp > deadline,'Deadline has not passed yet.');
    _;
  }
  modifier beforeDeadline() {
    require(block.timestamp <= deadline,'Deadline has passed');
    _;
  }
  modifier openWithdraw() {
    require(openForWithdraw == true, 'Staking pool is not currently open for withdrawal.');
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable beforeDeadline() {

    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public afterDeadline() {
    if(address(this).balance > threshold){
      exampleExternalContract.complete{value: address(this).balance}();
      openForWithdraw = false;
    }else{
      // If the `threshold` was not met, allow everyone to call a `withdraw()` function
      openForWithdraw = true;

    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public openWithdraw() afterDeadline() {
    if(openForWithdraw){
      payable(msg.sender).transfer(balances[msg.sender]);
      balances[msg.sender] = 0;
    }
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256){
    if(block.timestamp >= deadline){
      return 0;
    }else {
      return (deadline - block.timestamp);
    }
  }
  // Add the `receive()` special function that receives eth and calls stake()

  receive() external payable {
    stake();
  }

}
