import * as dotenv from 'dotenv';
dotenv.config();

export const deploy = async () => {
    let priv_key; // =  process.env['PRIVATE_KEY'];

    const { spawn } = await import("child_process");

    let rpc = 'http://127.0.0.1:8545'
   // rpc = process.env['RPC']!;
   
    let deployScriptPath = 'script/Deploy.s.sol:DeployScript ';
    let params = ['script',deployScriptPath,`--rpc-url=${rpc}`,'--broadcast'];

    if (priv_key) params.push(`--private-key=${priv_key}`)


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

deploy();

