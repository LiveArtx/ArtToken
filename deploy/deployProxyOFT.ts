import { type DeployFunction } from 'hardhat-deploy/types'
import { BigNumber } from 'ethers'

import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import assert from 'assert'

// To deploy:
// configure `layerzero.config` 
// configure `hardhat.config.ts`
// npx hardhat lz:deploy

const contractName = 'ArtTokenOFT'

const deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    const name = "ArtToken"
    const symbol = "ART"
    const initialSupply = BigNumber.from("1000000").mul(BigNumber.from("10").pow(18))

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
    console.log(`EndpointV2 address: ${address}`)

    const { newlyDeployed } = await deploy(contractName, {
        from: deployer,
        args: [address],
        log: true,
        waitConfirmations: 1,
        skipIfAlreadyDeployed: false,
        proxy: {
            proxyContract: 'OpenZeppelinTransparentProxy',
            owner: deployer,
            execute: {
                init: {
                    methodName: 'initialize',
                    args: [name, symbol, deployer, initialSupply],
                },
            },
        },
    })

    console.log(`Contract was ${newlyDeployed ? 'deployed' : 'not deployed'}`)
    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName]

export default deploy
