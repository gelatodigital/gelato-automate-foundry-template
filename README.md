# Gelato Foundry template for Automate

The purpose of this repo is to showcase examples of using Gelato Auomate in a Foundry enviroment. 


## Geting started

Fist we need to install Foundry in order to run `forge` commands. We can found all Foundry relevant information at the [Foundry book](https://book.getfoundry.sh/), and wth regards to [installation](https://book.getfoundry.sh/getting-started/installation). The method I've used is **build from source**

Once we have foundry installed we can move 

### forge init
We have inlcuded in this repo autoamte examples and added typescript support for some helper funcitons. Running `forge init` would create a fresh foudry repo. In our case we will clone this repo.

So let's go ahead:

`git clone https://github.com/gelato/gelato-foundry-automate-template`

`cd gelato-foundry-automate-template`

`yarn`



## forge vs helpers
There are three main commands in `forge`, `cast` and `anvil`.  `cast` is used to query the blockchain from the command line and we won't use it in this repo. `anvil` is used to spin a local blockchain node like hardhat.

When starting with foundry sometimes is difficult to remember the diferent cli commnads and parameters we need to use, therefore we have created a set of scripts to ease the foundry onboarding.

### anvil
The command we will use to fork mainnet will be:
`anvil --fork-url=RPC --fork-block-number=BLOCK_NUMBER`

We hace created a helper script to ne able to run
`npm run fork`

Specific avil params can fe found [here](https://book.getfoundry.sh/anvil/)

### forge test
The forge comand to run one specific test in a specific file would look like:

`forge test -vv' --fork-url=RPC --match-path=PATH_TO_FILE --match-test=TEST_NAME`

We have created a helper method in typescript [here]() where you can input the params and run a simple
`npm run test`

Specific test params can fe found [here](https://book.getfoundry.sh/reference/forge/forge-test)

  &nbsp; 
## Gelato Automate Examples

1) Before start to testing we would need to:
`copy .env-template to .env` and add the RPC you are using as well as the private key (pk only in case you want to deploy to testnet)

2) run `npm run fork`

3) run `npm run test`

In the contracts folder we have following contract structure

-- contractCreator
   -- wi 

The gelato folder contain all of the helper contracts that are needed for all of the examples.

This contract structure is replicated in the test folder with one test file `.t.sol` per contract.

We run 3 tests on every contract:

1 - Create a task and check if the TaskId is correct

2 - Create a task and execute expecting revert as we haven't any funds (either treasuty or contract)

3 - Create a task, fund the treasury or contract, execute the task and check if the cunter has increase in 1.

The test execution follows in every example this pattern:
```ts
 // impersonate Gelato executor
    vm.prank(executor); // Gelato executor address

     // recreate Module Data (exactly same code used by task creation)
    ModuleData memory moduleData =
      ModuleData({modules: new Module[](1), args: new bytes[](1)});

    moduleData.modules[0] = Module.RESOLVER;

    moduleData.args[0] =
      abi.encode(address(counter), abi.encodeCall(counter.checker, ()));

    // encode exec Data
    bytes memory execData =
      abi.encodeWithSelector(counter.increaseCount.selector, 1);

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
    ```

