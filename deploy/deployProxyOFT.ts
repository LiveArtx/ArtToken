import { type DeployFunction } from 'hardhat-deploy/types'

import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import assert from 'assert'

// To deploy:
// configure `layerzero.config` 
// configure `hardhat.config.ts`
// npx hardhat lz:deploy

const contractName = 'ArtTokenUpgradeable'

const deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { getNamedAccounts, deployments } = hre

    const { deterministic } = deployments
    const { deployer } = await getNamedAccounts()

    const name = "ArtToken"
    const symbol = "ART"
    // const owner = "0x7D40aC593332049a189Cd5AeF94B049657F14130";
    const initialSupply = 0;

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)


    const eid = hre.network.config.eid as EndpointId
    const lzNetworkName = endpointIdToNetwork(eid)

    const { address } = getDeploymentAddressAndAbi(lzNetworkName, 'EndpointV2')
    console.log(`EndpointV2 address: ${address}\n`)

    const { address: proxyAddress,
        implementationAddress,
        deploy } = await deterministic(contractName, {
            salt: process.env.DETERMINISTIC_SALT,
            from: deployer,
            args: [address],
            log: true,
            waitConfirmations: 1,
            skipIfAlreadyDeployed: false,
            proxy: {
                proxyContract: 'OpenZeppelinTransparentProxy',
                owner: deployer,
                checkProxyAdmin: true,
                execute: {
                    init: {
                        methodName: 'initialize',
                        args: [name, symbol, deployer, initialSupply],
                    }
                },
            },
        })

    const { newlyDeployed } = await deploy()

    console.log(`${hre.network.name} contract was ${newlyDeployed ? ' successfully deployed ✅' : 'failed to deploy ❌'}`)
    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, proxy address: ${proxyAddress}, implementation address: ${implementationAddress}\n`)
}

deploy.tags = [contractName]

export default deploy