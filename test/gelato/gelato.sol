// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { ModuleData, Module } from "../../src/gelato/Types.sol";

abstract contract Gelato is Test {
  address opsExecutor = address(0x3CACa7b48D0573D793d3b0279b5F0029180E83b6);

  constructor() { }

  function memorySliceSelector(bytes memory _bytes)
    internal
    pure
    returns (bytes4 selector)
  {
    selector = _bytes[0] | (bytes4(_bytes[1]) >> 8) | (bytes4(_bytes[2]) >> 16)
      | (bytes4(_bytes[3]) >> 24);
  }

  //   function gelatoBalance() internal {
  //     vm.startPrank(opsExecutor);
  //     (bool canExec, bytes memory execData) = poolProxy.checkerLastExecution();

  //     if (canExec) {
  //       bytes memory resolverData = abi.encodeWithSelector(poolProxy.checkerLastExecution.selector);

  //       bytes memory resolverArgs = abi.encode(address(poolProxy), resolverData);

  //       Module[] memory modules = new Module[](1);

  //       modules[0] = Module.RESOLVER;

  //       bytes[] memory args = new bytes[](1);

  //       args[0] = resolverArgs;

  //       ModuleData memory moduleData = ModuleData(modules, args);

  //       ops.exec(address(poolProxy), address(poolProxy), execData, moduleData, 0.01 ether, ETH, false, true);
  //     }

  //     vm.stopPrank();
  //   }

  /**
   * @notice Returns taskId of taskCreator.
   * @notice To maintain the taskId of legacy tasks, if
   * resolver module or resolver and time module is used,
   * we will compute task id the legacy way.
   *
   * @param taskCreator The address which created the task.
   * @param execAddress Address of contract that will be called by Gelato.
   * @param execSelector Signature of the function which will be called by Gelato.
   * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
   * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
   */
  function getTaskId(
    address taskCreator,
    address execAddress,
    bytes4 execSelector,
    ModuleData memory moduleData,
    address feeToken
  ) internal pure returns (bytes32 taskId) {
    if (_shouldGetLegacyTaskId(moduleData.modules)) {
      bytes32 resolverHash = _getResolverHash(moduleData.args[0]);

      taskId = getLegacyTaskId(
        taskCreator,
        execAddress,
        execSelector,
        feeToken == address(0),
        feeToken,
        resolverHash
      );
    } else {
      taskId = keccak256(
        abi.encode(taskCreator, execAddress, execSelector, moduleData, feeToken)
      );
    }
  }

  /**
   * @notice Returns taskId of taskCreator.
   * @notice Legacy way of computing taskId.
   *
   * @param taskCreator The address which created the task.
   * @param execAddress Address of contract that will be called by Gelato.
   * @param execSelector Signature of the function which will be called by Gelato.
   * @param useTaskTreasuryFunds Wether fee should be deducted from TaskTreasury.
   * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
   * @param resolverHash Hash of resolverAddress and resolverData {See getResolverHash}
   */
  function getLegacyTaskId(
    address taskCreator,
    address execAddress,
    bytes4 execSelector,
    bool useTaskTreasuryFunds,
    address feeToken,
    bytes32 resolverHash
  ) internal pure returns (bytes32) {
    return keccak256(
      abi.encode(
        taskCreator,
        execAddress,
        execSelector,
        useTaskTreasuryFunds,
        feeToken,
        resolverHash
      )
    );
  }

  /**
   * @dev For legacy tasks, resolvers are compulsory. Time tasks were also introduced.
   * The sequence of Module is enforced in {LibTaskModule-_validModules}
   */
  function _shouldGetLegacyTaskId(Module[] memory _modules)
    private
    pure
    returns (bool)
  {
    uint256 length = _modules.length;

    if (
      (length == 1 && _modules[0] == Module.RESOLVER)
        || (
          length == 2 && _modules[0] == Module.RESOLVER
            && _modules[1] == Module.TIME
        )
    ) {
      return true;
    }

    return false;
  }

  /**
   * @dev Acquire resolverHash which is required to compute legacyTaskId.
   *
   * @param _resolverModuleArg Encoded value of resolverAddress and resolverData
   */
  function _getResolverHash(bytes memory _resolverModuleArg)
    private
    pure
    returns (bytes32)
  {
    return keccak256(_resolverModuleArg);
  }
}
