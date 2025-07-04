import { task } from 'hardhat/config'

import { types } from '@layerzerolabs/devtools-evm-hardhat'
import { EndpointId, endpointIdToNetwork } from '@layerzerolabs/lz-definitions'
import { getDeploymentAddressAndAbi } from '@layerzerolabs/lz-evm-sdk-v2'

const proxyAdminABI = [
    {
      "inputs": [
        {
          "internalType": "contract TransparentUpgradeableProxy",
          "name": "proxy",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "implementation",
          "type": "address"
        }
      ],
      "name": "upgrade",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]

interface Args {
    proxyaddr: string
    proxyadminaddr: string
    impl: string
}

//! Set PRIVATE_KEY in .env

// Example Command:
// npx hardhat proxy:upgrade --proxyaddr 0x4DEC3139f4A6c638E26452d32181fe87A7530805 --proxyadminaddr 0x07095212518aE9EA64760E9F01f49D1618b18aC8 --impl ArtTokenUpgradeableV2 --network base

task('proxy:upgrade', 'upgrade art token proxy')
    .addParam('proxyaddr', 'proxy address', undefined, types.string)
    .addParam('proxyadminaddr', 'proxy admin address', undefined, types.string)
    .addParam('impl', 'new implementation contract name', undefined, types.string)
    .setAction(async (taskArgs: Args, { ethers, deployments, network }) => {
        try {

            const proxyAddress = taskArgs.proxyaddr
            const proxyAdminAddress = taskArgs.proxyadminaddr
            const implName = taskArgs.impl

            const [signer] = await ethers.getSigners()
            
            if (!network.config.eid) {
                throw new Error('Network endpoint ID (eid) not configured')
            }
            console.log("EID", network.config.eid);


            // create proxy instance
            const proxyAdminInstance = await ethers.getContractAt(proxyAdminABI, proxyAdminAddress)
                .catch(() => { throw new Error('Failed to get proxy contract instance') })


            // Get the endpoint address
            const eid = network.config.eid as EndpointId
            const lzNetworkName = endpointIdToNetwork(eid)
            console.log("LZ Network Name", lzNetworkName);
            const { address } = getDeploymentAddressAndAbi(lzNetworkName, 'EndpointV2')
            console.log("EndpointV2 address", address);

            if (!address) {
                throw new Error(`EndpointV2 address not found for network ${lzNetworkName}`)
            }
            console.log("EndpointV2 address found");

            // deploy the new implementation
            const implDeployment = await deployments.deploy(implName, {
                from: signer.address,
                log: true,
                deterministicDeployment: true,
                args: [address]
            }).catch((error) => {
                throw new Error(`Failed to deploy implementation: ${error.message}`)
            })
            
            console.log(`Implementation deployed to: ${implDeployment.address}`)

            // upgrade the proxy
            const upgradeTx = await proxyAdminInstance.upgrade( proxyAddress, implDeployment.address)
                .catch((error: Error) => {
                    throw new Error(`Failed to initiate upgrade transaction: ${error.message}`)
                })
            
            await upgradeTx.wait().then(() => {
                console.log("Upgrade transaction completed")
            }).catch((error: Error) => {
                    throw new Error(`Failed to complete upgrade transaction: ${error.message}`)
                })

        } catch (error: any) {
            console.error('Error during proxy upgrade:', error.message)
            throw error // Re-throw to ensure the task fails with non-zero exit code
        }
    })