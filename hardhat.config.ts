// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import '@nomiclabs/hardhat-etherscan'
import { HttpNetworkAccountsUserConfig } from 'hardhat/types'
// import '@openzeppelin/hardhat-upgrades'
import { EndpointId } from '@layerzerolabs/lz-definitions'

import './tasks/sendMessage';
import './tasks/upgradeProxy';

import { ethers } from 'ethers'

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
        ? [PRIVATE_KEY]
        : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config  = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    defaultNetwork: 'hardhat',
    networks: {
        'base-testnet': {
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: `https://base-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts,
            gasPrice: 25000000000,
            priorityFee: ethers.utils.parseUnits("3", "gwei"),
            maxFee: ethers.utils.parseUnits("5", "gwei"),
        },
        'linea-testnet': {
            eid: EndpointId.LINEASEP_V2_TESTNET,
            url: `https://linea-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts,
            gasPrice: 25000000000,
            priorityFee: ethers.utils.parseUnits("3", "gwei"),
            maxFee: ethers.utils.parseUnits("5", "gwei"),
        },
        hardhat: {
            // Need this for testing because TestHelperOz5.sol is exceeding the compiled contract size limit
            allowUnlimitedContractSize: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
    etherscan: {
        apiKey: {
            // 'base-testnet': 'process.env.ETHERSCAN_BASE_API_KEY',
            'base-testnet': process.env.BLOCKSCOUT_API_KEY,
            'linea-testnet': process.env.ETHERSCAN_LINEA_API_KEY,
        },
        customChains: [
            {
                network: 'base-testnet',
                chainId: 84532,
                urls: {
                    // apiURL: 'https://api-sepolia.basescan.org/api',
                    apiURL: 'https://base-sepolia.blockscout.com/api',
                    // browserURL: 'https://basescan.org',
                    browserURL: 'https://base-sepolia.blockscout.com/',
                },
            },
            // {
            //     network: 'linea',
            //     chainId: 59144,
            //     urls: {
            //         apiURL: 'https://api.lineascan.build/api',
            //         browserURL: 'https://lineascan.build/',
            //     },
            // },
            {
                network: 'linea-testnet',
                chainId: 59141,
                urls: {
                    apiURL: 'https://api-sepolia.lineascan.build/api',
                    browserURL: 'https://sepolia.lineascan.build/address',
                },
            },

        ],
    },
}

export default config