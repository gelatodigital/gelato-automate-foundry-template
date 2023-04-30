// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Counter.sol";
import { IAutomate } from "../src/gelato/IAutomate.sol";
import { Module } from "../src/gelato/Types.sol";

contract DeployScript is Script {
  Countertoto public counter;
  address ops = address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F); // address(0xc1C6805B857Bef1f412519C4A842522431aFed39);
  address treasury = address(0xF381dfd7a139caaB83c26140e5595C0b85DDadCd);
  address deployer = address(0x7A84b3CaAC4C00AFA0886cb2238dbb9788376581);
  address executor = address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);
  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function memorySliceSelector(bytes memory _bytes)
    internal
    pure
    returns (bytes4 selector)
  {
    selector = _bytes[0] | (bytes4(_bytes[1]) >> 8) | (bytes4(_bytes[2]) >> 16)
      | (bytes4(_bytes[3]) >> 24);
  }

  function setUp() public { }

  function run() public {
    // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // vm.startBroadcast(deployerPrivateKey);
    // address signer = vm.addr(deployerPrivateKey);
    vm.prank(deployer);
    //vm.startBroadcast(deployer);
    console.log(deployer);
    counter = new Countertoto (ops, ops);
    payable(address(counter)).transfer(0.01 ether);

    console.log(address(counter));

    Module[] memory modules = new Module[](0);

    // modules[0] = Module.RESOLVER;

    bytes[] memory args = new bytes[](0);

    ModuleData memory moduleData = ModuleData(modules, args);

    console.log(counter.number());

    bytes memory execData =
      abi.encodeWithSelector(counter.setNumber.selector, 10);

    bytes4 selector = memorySliceSelector(execData);
    bytes32 taskId = keccak256(
      abi.encode(address(counter), address(counter), selector, moduleData, ETH)
    );
    console.logBytes32(taskId);

    vm.prank(executor);

    IAutomate(ops).exec(
      address(counter),
      address(counter),
      execData,
      moduleData,
      0.01 ether,
      ETH,
      false,
      true
    );
    console.log(counter.number());
    // vm.stopBroadcast();
  }
}
