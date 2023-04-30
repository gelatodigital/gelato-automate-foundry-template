// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import { AutomateTaskCreator } from "./gelato/AutomateTaskCreator.sol";
import { IAutomate } from "./gelato/IAutomate.sol";
import { ModuleData, Module } from "./gelato/Types.sol";

contract Countertoto is AutomateTaskCreator {
  address owner;

  uint256 public number = 1;
  bytes32 public taskId;

  constructor(address _automate, address _fundsOwner)
    AutomateTaskCreator(_automate, _fundsOwner)
  {
    owner = msg.sender;
    createTaskEveryBlock();
  }

  function createTaskEveryBlock() public onlyOneTask {
    address execAddress = address(this);

    bytes memory execData = abi.encodeWithSelector(this.setNumber.selector, 2);

    Module[] memory modules = new Module[](0);

    // modules[0] = Module.RESOLVER;

    bytes[] memory args = new bytes[](0);

    ModuleData memory moduleData = ModuleData(modules, args);

    taskId = automate.createTask(execAddress, execData, moduleData, ETH);
  }

  function setNumber(uint256 newNumber) external onlyAutomate {
    (uint256 fee, address feeToken) = automate.getFeeDetails();

    _transfer(fee, feeToken);

    number = newNumber + number;
  }

  /// helpers
  function cancelTask() public {
    require(taskId != bytes32(0), "NO_TASK");
    automate.cancelTask(taskId);
    taskId = bytes32(0);
  }

  // modifiers
  modifier onlyOneTask() {
    require(taskId == bytes32(0), "ONLY_ONE_TASK");
    _;
  }

  receive() external payable { }

  function withdraw() external returns (bool) {
    require(owner == msg.sender, "NOT_ALLOWED");

    (bool result,) = payable(msg.sender).call{value: address(this).balance}("");
    return result;
  }
}
