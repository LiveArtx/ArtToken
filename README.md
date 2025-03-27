# ArtToken Smart Contracts

## Overview

This is the smart contract for the ArtToken. It is a upgradeable contract that uses the LayerZero protocol to send and receive tokens between different chains.

## Official Documentation
* [LayerZero Documentation](https://docs.layerzero.network/v2)
* [Deployed Endpoints, Message Libraries, and Executors](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)
* [OFT Standard Specification](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)
* [Options Generator](https://remix.ethereum.org/#url=https://docs.layerzero.network/LayerZero/contracts/OptionsGenerator.sol&lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.24+commit.e11b9ed9.js)
* [LayerZero Scan](https://docs.layerzero.network/v2/developers/evm/technical-reference/layerzero-scan)
* [Deploying Contracts](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/deploying)
* [Configuring Contracts](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways)

## Project Structure

```
├─ contracts/
│   ├─ ArtToken.sol — "Standard non-upgradeable ArtToken contract"
│   ├─ ArtTokenUpgradeable.sol — "Upgradeable ArtToken contract"
│   ├─ archive/ — "Archived contract versions"
│   └─ libraries/ — "Shared libraries"
├─ deploy/ — "Deployment scripts"
├─ test/ — "Test files"
├─ tasks/ — "Hardhat tasks"
└─ deployments/ — "Deployment artifacts"
```

## Prerequisites

- Node.js and Yarn
- Hardhat
- Foundry (for testing)

## Setup

1. Clone the repository
2. Install dependencies:
```bash
yarn install
```

3. Copy `.env.example` to `.env` and fill in your values:
```bash
cp .env.example .env
```

## Testing

The project uses Foundry as the primary testing framework. To run tests:

```bash
# Run Foundry tests
yarn test

# For verbose output
forge test -vv

# Generate coverage report
In terminal run `export ALCHEMY_URL=""`
yarn coverage:build

# View coverage report in browser
yarn coverage:view
```

Note: While the project includes Hardhat configuration, Foundry is the recommended testing framework for this project.

## Deployment Steps

1. Save a salt in env —> `DETERMINISTIC_SALT=<your salt here>`
2. Configure `hardhat.config.ts`
    - [Configuring Contracts](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways)
3. Deploy contracts:
```bash
npx hardhat lz:deploy --stage testnet --tags ArtTokenOFT --reset
```
4. Verify contracts:
```bash
npx hardhat verify <Implementation Contract Address> --network base-testnet <EndpointV2 address - constructor arg>
```
5. Configure `layerzero.simple.config.ts`:
```bash
npx hardhat lz:oapp:wire --oapp-config layerzero.simple.config.ts
```

## Manual Configuration (Optional)

Set peer contracts using the `setPeer` function in the deployed proxy contract. It requires:
- `_eid`: the endpoint id of the deployed contract
- `_peer`: the address of the peer contract zero padded to 32 bytes

## Endpoints IDs

- Base Testnet: 40245
- Linea Testnet: 40287
- [EID Table](https://docs.layerzero.network/v2/deployments/deployed-contracts)

## Zero Padding Example

For setting peer addresses:
1. 000000000000000000000000 (padding)
2. 0xEeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0 (peer contract address)
3. 0x000000000000000000000000Eeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0 (bytes32)
(0x + padding + peer contract address, minus the 0x)

## LayerZero Options

For sending tokens between chains, use the Options Generator to create options with:
- `_gasLimit`: 200000
- `_value`: 0

Example options:
```javascript
const options = "0x00030100210100000000000000000000000000030d400000000000000000000000000000000a";
```

Send parameters:
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

const tx = await oftContract.send(
    sendParam,
    messagingFee,
    refundAddress,
    { value: ethers.BigNumber.from(nativeFee.toString()) }
);
```

## UI for Sending Tokens

A simple UI for sending tokens between chains is available in `index.html`. You can also use the [Send Tokens](https://codepen.io/passandscore-the-sasster/full/emYVwWz) interface.

