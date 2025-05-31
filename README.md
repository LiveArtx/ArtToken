# ART Token Smart Contracts

## Overview
The ART Token is an advanced ERC20 token implementation featuring cross-chain compatibility through LayerZero protocol

## Documentation
- [Cross-Chain Compatibility](./docs/cross-chain-compatibility.md) - Guide for LayerZero integration and cross-chain operations
- [Running Tests](./docs/run-unit-tests.md) - Guide for executing and managing tests

## Project Structure

```bash
├─ contracts/
│ └─ ArtTokenUpgradeable.sol # Upgradeable ArtToken contract
├─ deploy/ # Deployment scripts
├─ test/ # Test files
├─ docs/ # Documentation
├─ tasks/ # Hardhat tasks
└─ deployments/ # Deployment artifacts
```

## Development Setup

### Prerequisites
- Node.js and Yarn
- Hardhat
- Foundry

### Installation
```bash
# Install dependencies
yarn install

# Setup environment variables
cp .env.example .env
```

## License
[MIT License](LICENSE)