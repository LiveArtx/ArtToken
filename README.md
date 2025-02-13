# ArtToken Smart Contract

## Overview

The ArtToken repository contains the implementation of an ERC20 token with additional features such as capped supply, upgradeability, and a merkle tree-based token claiming mechanism. The contract is designed to be used in a decentralized application where tokens can be claimed by users based on their allocation in a merkle tree.

## Features

- **ERC20 Standard**: Implements the ERC20 token standard with additional functionalities.
- **Capped Supply**: The total supply of tokens is capped at 1 billion tokens.
- **Upgradeable**: Utilizes the UUPS (Universal Upgradeable Proxy Standard) pattern for upgradeability.
- **Merkle Tree Claiming**: Allows users to claim tokens based on their allocation in a merkle tree.
- **Burnable**: Tokens can be burned, reducing the total supply.
- **Staking Integration**: Supports claiming tokens directly to a staking contract.

## Contract Details

- **Token Name**: ART TOKEN
- **Token Symbol**: ART
- **Decimals**: 18
- **Max Supply**: 1,000,000,000 ART

## Prerequisites

- **Node.js**: Ensure you have Node.js version 20 or higher installed. This is required for managing dependencies and running scripts.

## Security Considerations

- **Access Control**: The contract uses OpenZeppelin's `Ownable` for access control, ensuring only the owner can perform sensitive operations like minting and setting the staking contract address.
- **Upgradeability**: The contract is upgradeable using the UUPS pattern, which requires careful management of the proxy and implementation contracts.
- **Merkle Tree**: The merkle tree mechanism is used for secure and efficient token distribution. Ensure the merkle root is correctly set and verified.
- **Burn Functionality**: Tokens can be burned by users, which affects the total supply and cap calculations.

## Testing

The repository includes a comprehensive suite of tests written in Solidity using the Forge testing framework. These tests cover:

- Basic ERC20 functionality
- Upgradeability
- Claiming tokens using the merkle tree
- Burning tokens
- Setting and using the staking contract

### Running Tests

To run the tests, ensure you have Foundry installed and set up. Then, execute the following command in your terminal:

```bash
forge test
```

This command will compile the contracts and run all the tests in the `test` directory, providing you with detailed output on the test results.

## Setup and Deployment

1. **Install Dependencies**: Ensure you have the necessary tools and libraries installed, such as Foundry and OpenZeppelin contracts.
2. **Compile Contracts**: Use Foundry to compile the smart contracts.
3. **Deploy Contracts**: Deploy the contracts using a deployment script or manually through a tool like Remix or Hardhat.
4. **Run Tests**: Execute the test suite to ensure all functionalities are working as expected.

## Audit Checklist

- Verify the correctness of the merkle tree implementation and proof verification.
- Ensure proper access control is enforced throughout the contract.
- Review the upgradeability mechanism and ensure it is secure.
- Check for any potential reentrancy vulnerabilities, especially in functions that transfer tokens.
- Validate the burn functionality and its impact on the total supply and cap.

## Contact

For any questions or issues, please contact the development team at [jason@liveart.io].
