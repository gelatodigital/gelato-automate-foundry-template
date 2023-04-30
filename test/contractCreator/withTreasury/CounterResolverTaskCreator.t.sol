// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import
  "../../../src/contractCreator/withTreasury/CounterResolverTaskCreator.sol";
import { ITaskTreasuryUpgradable } from
  "../../../src/gelato/ITaskTreasuryUpgradable.sol";
import { IAutomate } from "../../../src/gelato/IAutomate.sol";
import {
  IOpsProxyFactory, ModuleData, Module
} from "../../../src/gelato/Types.sol";
import { Gelato } from "../../gelato/Gelato.sol";

contract CounterTest is Test, Gelato {
  CounterResolverTaskCreator public counter;

  address user1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

  // GELATO Mainnet addresses
  // https://docs.gelato.network/developer-services/automate/contract-addresses

  address automate = address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);
  address treasury = address(0x2807B4aE232b624023f87d0e237A3B1bf200Fd99);
  address executor = address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);
  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function setUp() public {
    counter = new CounterResolverTaskCreator(payable(automate), user1);
  }

  // @dev check if the taskId is the expected
  function testTaskId() public {
    counter.createTask();

    // manually calculate taskI

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] =
      abi.encode(address(counter), abi.encodeCall(counter.checker, ()));
    moduleData.args[1] = bytes("");

    bytes32 taskId = getTaskId(
      address(counter),
      address(counter),
      counter.increaseCount.selector,
      moduleData,
      address(0)
    );

    assertTrue(counter.taskId() == taskId, "TaskID OK");
  }

  // @dev execution should revert without funding treasury
  function testExecRevertWOFunds() public {
    counter.createTask();
    uint256 count = counter.count();
    console.logUint(count);

    // impersonate Gelato executor
    vm.prank(executor);

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] =
      abi.encode(address(counter), abi.encodeCall(counter.checker, ()));
    moduleData.args[1] = bytes("");

    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

    vm.expectRevert("TaskTreasury: Not enough funds");
    IAutomate(automate).exec(
      address(counter),
      address(counter),
      execData,
      moduleData,
      0.01 ether,
      ETH,
      true,
      true
    );
  }

  // @dev execution should run as expected an increase counter by 1 as by fund the treasury
  function testExec() public {
    counter.createTask();
    uint256 count = counter.count();

    // fund the treaury account for the counter contract
    ITaskTreasuryUpgradable(treasury).depositFunds{value: 1 ether}(
      address(counter), ETH, 1 ether
    );

    // impersonate Gelato executor
    vm.prank(executor);

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] =
      abi.encode(address(counter), abi.encodeCall(counter.checker, ()));
    moduleData.args[1] = bytes("");

    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

    IAutomate(automate).exec(
      address(counter),
      address(counter),
      execData,
      moduleData,
      0.01 ether,
      ETH,
      true,
      true
    );

    uint256 countafter = counter.count();

    assertTrue(count + 1 == countafter, "EXEC OK");
  }
}
