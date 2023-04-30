import * as dotenv from 'dotenv';
dotenv.config();

export const test = async () => {
  
    const { spawn } = await import("child_process");

    let rpc = 'http://127.0.0.1:8545'
    // rpc = process.env['RPC']!;

    const params = ['test', '-vv',`--fork-url=${rpc}`]

    let path; // = 'test/contractCreator/withoutTreasury/CounterSingleExecTaskCreatorWT.t.sol
    if (path) params.push(`--match-path=${path}`)

    let test; // = 'testTaskId'
    if (test) params.push(`--match-test=${test}`)


    console.log(params)

    const childProcess = spawn('forge', params, {
        stdio: "inherit",
      });
    

    childProcess.once("close", (status) => {
        childProcess.removeAllListeners("error");
  
        if (status === 0) {
        console.log('ok')
        } else {
            console.log('error')
        }
        
      });
  
      childProcess.once("error", (_status) => {
        childProcess.removeAllListeners("close");
        console.log('error')
      });

}

test()

//anvil --fork-block-number 7850256 -f https://goerli.infura.io/v3/1e43f3d31eea4244bf25ed4c13bfde0e
//forge test --fork-url http://127.0.0.1:8545 -vv --match-test testFuzzDeposit