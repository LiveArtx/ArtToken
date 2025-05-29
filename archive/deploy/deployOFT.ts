import { type DeployFunction } from 'hardhat-deploy/types'

import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import assert from 'assert'

// To deploy:
// configure `layerzero.config` 
// configure `hardhat.config.ts`
// npx hardhat lz:deploy

const contractName = 'ArtToken'

const deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { getNamedAccounts, deployments } = hre

    const { deterministic } = deployments
    const { deployer } = await getNamedAccounts()

    const name = "ArtToken"
    const symbol = "ART"
    const initialSupply = 1000000;

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    // This is an external deployment pulled in from @layerzerolabs/lz-evm-sdk-v2
    //
    // @layerzerolabs/toolbox-hardhat takes care of plugging in the external deployments
    // from @layerzerolabs packages based on the configuration in your hardhat config
    //
    // For this to work correctly, your network config must define an eid property
    // set to `EndpointId` as defined in @layerzerolabs/lz-definitions
    //
    // For example:
    //
    // networks: {
    //   fuji: {
    //     ...
    //     eid: EndpointId.AVALANCHE_V2_TESTNET
    //   }
    // }

    const eid = hre.network.config.eid as EndpointId
    const lzNetworkName = endpointIdToNetwork(eid)

    const { address } = getDeploymentAddressAndAbi(lzNetworkName, 'EndpointV2')
    console.log(`EndpointV2 address: ${address}\n`)

    const { address: contractAddress, deploy } = await deterministic(contractName, {
        salt: process.env.DETERMINISTIC_SALT,
        from: deployer,
        args: [name, symbol, address, deployer, initialSupply],
        log: true,
        waitConfirmations: 1,
        skipIfAlreadyDeployed: false,
    })

    const { newlyDeployed } = await deploy()

    console.log(`${hre.network.name} contract was ${newlyDeployed ? ' successfully deployed ✅' : 'failed to deploy ❌'}`)
    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${contractAddress}\n`)
}

deploy.tags = [contractName]

export default deploy