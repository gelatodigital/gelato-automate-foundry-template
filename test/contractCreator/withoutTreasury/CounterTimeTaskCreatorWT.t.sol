// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import
  "../../../src/contractCreator/withoutTreasury/CounterTimeTaskCreatorWT.sol";
import { IAutomate } from "../../../src/gelato/IAutomate.sol";
import {
  IOpsProxyFactory, ModuleData, Module
} from "../../../src/gelato/Types.sol";
import { IOpsProxy } from "../../../src/gelato/IOpsProxy.sol";
import { Gelato } from "../../gelato/Gelato.sol";

contract CounterTest is Test, Gelato {
  CounterTimeTaskCreatorWT public counter;

  address user1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
  uint256 public constant INTERVAL = 3 minutes;
  // GELATO Mainnet addresses
  // https://docs.gelato.network/developer-services/automate/contract-addresses

  address automate = address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);
  address treasury = address(0x2807B4aE232b624023f87d0e237A3B1bf200Fd99);
  address executor = address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);
  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

  function setUp() public {
    counter = new CounterTimeTaskCreatorWT(payable(automate), user1);
  }

  // @dev check if the taskId is the expected
  function testTaskId() public {
    vm.prank(user1);

    counter.createTask();

    // manually calculate taskId
    bytes memory execData = abi.encodeCall(counter.increaseCount, (1));

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});
    moduleData.modules[0] = Module.TIME;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(uint128(block.timestamp), uint128(INTERVAL));
    moduleData.args[1] = bytes("");

    bytes32 taskId = getTaskId(
      address(counter),
      address(counter),
      counter.increaseCount.selector,
      moduleData,
      ETH
    );

    assertTrue(counter.taskId() == taskId, "TaskID OK");
  }

  // @dev execution should revert
  function testRevertExecWOFunds() public {
    counter.createTask();
    uint256 count = counter.count();
    console.logUint(count);

    // impersonate Gelato executor
    vm.prank(executor);

    bytes memory execData = abi.encodeCall(counter.increaseCount, (1));

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});
    moduleData.modules[0] = Module.TIME;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(uint128(block.timestamp), uint128(INTERVAL));
    moduleData.args[1] = bytes("");

    vm.expectRevert(
      "Automate.exec: OpsProxy.executeCall: _transfer: ETH transfer failed"
    );
    IAutomate(automate).exec(
      address(counter),
      address(counter),
      execData,
      moduleData,
      0.01 ether,
      ETH,
      false,
      true
    );
  }

  // @dev execution should run as expected an increase counter by 1
  function testExec() public {
    payable(counter).transfer(1 ether);

    vm.prank(user1);
    counter.createTask();
    uint256 count = counter.count();

    IOpsProxyFactory(OPS_PROXY_FACTORY).deploy();

    (address dedicatedMsgSender, bool isDeployed) =
      IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(address(counter));

    console.log(isDeployed);

    bytes memory execData = abi.encodeCall(counter.increaseCount, (1));

    ModuleData memory moduleData =
      ModuleData({modules: new Module[](2), args: new bytes[](2)});
    moduleData.modules[0] = Module.TIME;
    moduleData.modules[1] = Module.PROXY;

    moduleData.args[0] = abi.encode(uint128(block.timestamp), uint128(INTERVAL));
    moduleData.args[1] = bytes("");

    // impersonate Gelato executor
    vm.prank(executor);
    IAutomate(automate).exec(
      address(counter),
      address(counter),
      execData,
      moduleData,
      0.01 ether,
      ETH,
      false,
      true
    );

    uint256 countAfter = counter.count();
    console.log(countAfter);
    assertTrue(count + 1 == countAfter, "EXEC OK");
  }
}
