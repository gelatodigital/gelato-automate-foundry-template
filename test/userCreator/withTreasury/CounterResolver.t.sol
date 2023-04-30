// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Counter } from "../../../src/userCreator/withTreasury/Counter.sol";
import {
  CounterResolver,
  ICounter
} from "../../../src/userCreator/withTreasury/CounterResolver.sol";
import { ITaskTreasuryUpgradable } from
  "../../../src/gelato/ITaskTreasuryUpgradable.sol";
import { IAutomate } from "../../../src/gelato/IAutomate.sol";
import {
  IOpsProxyFactory, ModuleData, Module
} from "../../../src/gelato/Types.sol";
import { Gelato } from "../../gelato/Gelato.sol";

contract CounterTest is Test, Gelato {
  Counter public counter;
  CounterResolver public counterResolver;

  address user1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

  // GELATO Mainnet addresses
  // https://docs.gelato.network/developer-services/automate/contract-addresses

  address automate = address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);
  address treasury = address(0x2807B4aE232b624023f87d0e237A3B1bf200Fd99);
  address executor = address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);
  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function setUp() public {
    counter = new Counter(payable(automate), user1);
    counterResolver = new CounterResolver(ICounter(address(counter)));
  }

  // @dev check if the taskId is the expected
  function testTaskId() public {
    vm.prank(user1);
    // manually calculate taskId
    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(
      address(counterResolver), abi.encodeCall(counterResolver.checker, ())
    );
    moduleData.args[1] = bytes("");

    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

    bytes32 id = IAutomate(automate).createTask(
      address(counter), execData, moduleData, ETH
    );

    bytes32 taskId = getTaskId(
      user1, address(counter), counter.increaseCount.selector, moduleData, ETH
    );

    assertTrue(id == taskId, "TaskID OK");
  }

  // @dev execution should revert
  function testExecRevertWOFunds() public {
    uint256 count = counter.count();
    console.logUint(count);

    // impersonate Gelato executor

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(
      address(counterResolver), abi.encodeCall(counterResolver.checker, ())
    );
    moduleData.args[1] = bytes("");

    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

    vm.prank(user1);
    IAutomate(automate).createTask(
      address(counter), execData, moduleData, address(0)
    );

    vm.prank(executor);

    vm.expectRevert("TaskTreasury: Not enough funds");
    IAutomate(automate).exec(
      user1, address(counter), execData, moduleData, 0.01 ether, ETH, true, true
    );
  }

  // @dev execution should run as expected an increase counter by 1
  function testExec() public {
    uint256 count = counter.count();

    // impersonate Gelato executor

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});

    moduleData.modules[0] = Module.RESOLVER;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(
      address(counterResolver), abi.encodeCall(counterResolver.checker, ())
    );
    moduleData.args[1] = bytes("");

    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

    vm.prank(user1);
    IAutomate(automate).createTask(
      address(counter), execData, moduleData, address(0)
    );

    ITaskTreasuryUpgradable(treasury).depositFunds{value: 1 ether}(
      user1, ETH, 1 ether
    );

    vm.prank(executor);

    IAutomate(automate).exec(
      user1, address(counter), execData, moduleData, 0.01 ether, ETH, true, true
    );

    uint256 countafter = counter.count();

    assertTrue(count + 1 == countafter, "EXEC OK");
  }
}
