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
import { HttpNetworkAccountsUserConfig } from 'hardhat/types'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import "@nomicfoundation/hardhat-verify";

import './tasks/sendMessage';
import './tasks/upgradeProxy';

import { ethers } from 'ethers'

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY

// Validate Alchemy API key
if (!ALCHEMY_API_KEY) {
    console.warn('ALCHEMY_API_KEY not found in environment variables. Some networks may not work properly.')
}

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

const config = {
    paths: {
        cache: 'cache/hardhat',
    },
    solidity: {
        compilers: [
            {
                version: '0.8.26',
                settings: {
                    viaIR: true,
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
        'sepolia': {
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts,
        },
        'base': {
            eid: EndpointId.BASE_V2_MAINNET,
            url: `https://base-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts,
            priorityFee: ethers.utils.parseUnits("3", "gwei"),
            maxFee: ethers.utils.parseUnits("5", "gwei"),
        },
        'bsc': {
            eid: EndpointId.BSC_V2_MAINNET,
            url: `https://bnb-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts,
            gasPrice: 8000000000,
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
            // 'base-testnet': process.env.BLOCKSCOUT_API_KEY,
            // 'linea-testnet': process.env.ETHERSCAN_LINEA_API_KEY,
            // 'sepolia': process.env.ETHERSCAN_ETH_API_KEY,
            'base': process.env.ETHERSCAN_API_KEY,
            'bsc': process.env.ETHERSCAN_API_KEY,
        },
        customChains: [
            {
                network: "base",
                chainId: 8453,
                urls: {
                  apiURL: "https://api.basescan.org/api",
                  browserURL: "https://basescan.org",
                },
              },
              {
                network: "bsc",
                chainId: 56,
                urls: {
                  apiURL: "https://api.bscscan.com/api",
                  browserURL: "https://bscscan.com",
                },
              },
            // {
            //     network: 'base-testnet',
            //     chainId: 84532,
            //     urls: {
            //         // apiURL: 'https://api-sepolia.basescan.org/api',
            //         apiURL: 'https://base-sepolia.blockscout.com/api',
            //         // browserURL: 'https://basescan.org',
            //         browserURL: 'https://base-sepolia.blockscout.com/',
            //     },
            // },
            // {
            //     network: 'linea',
            //     chainId: 59144,
            //     urls: {
            //         apiURL: 'https://api.lineascan.build/api',
            //         browserURL: 'https://lineascan.build/',
            //     },
            // },
            // {
            //     network: 'linea-testnet',
            //     chainId: 59141,
            //     urls: {
            //         apiURL: 'https://api-sepolia.lineascan.build/api',
            //         browserURL: 'https://sepolia.lineascan.build/address',
            //     },
            // },
            // {
            //     network: 'sepolia',
            //     chainId: 11155111,
            //     urls: {
            //         apiURL: 'https://eth-sepolia.blockscout.com/api',
            //         browserURL: 'https://eth-sepolia.blockscout.com/',
            //     },
            // },
        ],
    },
}

export default config