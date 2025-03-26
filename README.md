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


## Upgradeable Contracts

The Solidity smart contracts are located in the `contracts` directory.

```ml
├─ ArtToken.sol — "Standard Upgradeable ArtToken contract"
├─ ArtTokenUpgradeableOFT.sol — "Upgradeable ArtToken contract for LayerZero"
├─ upgrades/
│   ├─ ArtTokenUpgradeableOFT2.sol — "Test v2 implementation"

```

## Test
```bash
forge clean
yarn run test
```

 * This script injects annotations into @layerzerolabs/oft-evm-upgradeable/contracts and @layerzerolabs/oapp-evm-upgradeable/contracts files.
 * It is used to prevent the compiler from throwing warnings about the @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable annotation when compiling/upgrading the contracts.

## Deployment Steps
1. Save a salt in env —> DETERMINISTIC_SALT=<your salt here>
2. configure `hardhat.config.ts`
    - [Configuring Contracts](https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways)
3. npx hardhat lz:deploy --stage testnet --tags ArtTokenOFT --reset
4. Verify contracts
    - npx hardhat verify <Implementation Contract Address> --network base-testnet <EndpointV2 address - constructor arg>
5. configure `layerzero.simple.config.ts`
    - npx hardhat lz:oapp:wire --oapp-config layerzero.simple.config.ts
6. setPeer (Optional - Manual) contracts - use the `setPeer` function in the deployed proxy contract. It requires the following parameters:
    - _eid: the endpoint id of the deployed contract
    - _peer: the address of the peer contract zero padded to 32 bytes
    

## Endpoints IDs

- Base Testnet: 40245
- Linea Testnet: 40287
- [EID Table](https://docs.layerzero.network/v2/deployments/deployed-contracts)

## Zero padding

_peer: the address of the peer contract zero padded to 32 bytes

example: 
1. 000000000000000000000000 (padding)
2. 0xEeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0 (peer contract address)
3. 0x000000000000000000000000Eeec2DA1372cC2BE54354acb2a501Bcc4d4EcCA0 (bytes32)
(0x + padding + peer contract address, minus the 0x)


## Options Generator --> createLzReceiveOption
- _gasLimit 200000
- _value 0

```javascript
 const options = "0x00030100210100000000000000000000000000030d400000000000000000000000000000000a";
```

These options are used when sending tokens from one chain to another.

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
## Notes
- Use the Options Generator to generate the options for the send function.
Remix: https://remix.ethereum.org/#url=https://docs.layerzero.network/LayerZero/contracts/OptionsGenerator.sol&lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.24+commit.e11b9ed9.js
- Refer to `index.html` to send tokens from one chain to another.

## UI for sending tokens

- [Send Tokens](https://codepen.io/passandscore-the-sasster/full/emYVwWz)