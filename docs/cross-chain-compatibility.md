# Cross-Chain Compatibility with LayerZero

## Overview
The ArtToken implements cross-chain functionality using the LayerZero protocol, allowing tokens to be sent and received between different blockchain networks. This document outlines the technical details and configuration requirements for cross-chain operations.

## Official LayerZero Resources
- [LayerZero Documentation](https://docs.layerzero.network/v2)
- [Deployed Endpoints, Message Libraries, and Executors](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)
- [OFT Standard Specification](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)
- [LayerZero Scan](https://layerzeroscan.com/)

## Configuration Tools
- [Options Generator](https://remix.ethereum.org/#url=https://docs.layerzero.network/LayerZero/contracts/OptionsGenerator.sol&lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.24+commit.e11b9ed9.js)
- [Token Transfer Interface](https://layer-zero-token-transfer.vercel.app/)

## Endpoint IDs
Reference table for supported networks:
- Base Testnet: 40245
- Linea Testnet: 40287
- [Complete EID Table](https://docs.layerzero.network/v2/deployments/deployed-contracts)

## Configuration Process

### 1. Contract Deployment
```bash
npx hardhat lz:deploy --stage testnet --tags ArtTokenUpgradeable --reset
```

### 2. Contract Verification
- Verify the implementation contract for each chain
```bash
npx hardhat verify <Implementation Contract Address> --network base-testnet <EndpointV2 address>
```

### 3. Wire OApp Configuration
Configure `layerzero.simple.config.ts` with the proxy contract name, then run:
```bash
npx hardhat lz:oapp:wire --oapp-config layerzero.simple.config.ts
```
- *Note: This step may take error when attempting to sign some of the transactions. Wait a few minutes and try again.*

### 4. Manual Peer Configuration
Use the `setPeer` function to configure peer contracts across chains:

#### Parameters:
- `_eid`: Endpoint ID of the target chain
- `_peer`: Address of the peer contract (32-byte padded)

#### Address Padding Example:
To convert a contract address to the required format:
1. Padding: `000000000000000000000000`
2. Address: `0xEeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0`
3. Result: `0x000000000000000000000000Eeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0`

## Cross-Chain Token Transfer

### Options Configuration
Use the LayerZero Options Generator with these recommended parameters:
- Gas Limit: 200,000
- Value: 0

Example options string:
```javascript
const options = "0x00030100210100000000000000000000000000030d400000000000000000000000000000000a";
```

### Send Parameters
```javascript
const sendParam = [
    parseInt(destinationChainId), // dstEid
    recipientEncoded,             // to
    amountWei,                    // amountLD
    amountWei,                    // minAmountLD
    options,                      // extraOptions
    "0x",                         // composeMsg
    "0x"                          // oftCmd
];
```

### Transaction Example
```javascript
const tx = await oftContract.send(
    sendParam,
    messagingFee,
    refundAddress,
    { value: ethers.BigNumber.from(nativeFee.toString()) }
);
```

## Deployment Resources
- [Deploying Contracts Guide](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/deploying)
- [Configuring Contract Pathways](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways)

## Testing Cross-Chain Functionality
When testing cross-chain operations:
1. Ensure proper endpoint configuration
2. Verify peer contract settings
3. Test with small amounts first
4. Monitor transactions on LayerZero Scan
5. Verify token balances on both chains

## Security Considerations
- Always verify peer contract addresses
- Use recommended gas limits
- Test thoroughly on testnets before mainnet deployment
- Monitor cross-chain transactions
- Keep deployment credentials secure
