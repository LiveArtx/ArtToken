# ART Token Smart Contracts

## Overview
The ART Token is an advanced ERC20 token implementation featuring cross-chain compatibility through LayerZero protocol and a sophisticated token claiming system with vesting capabilities.

## Documentation
- [Token Claiming System](./test/docs/claiming-overview.md) - Detailed explanation of the vesting and claiming mechanisms
- [Cross-Chain Compatibility](./docs/cross-chain-compatibility.md) - Guide for LayerZero integration and cross-chain operations
- [Running Tests](./docs/run-unit-tests.md) - Guide for executing and managing tests

## Project Structure

```bash
├─ contracts/
│ ├─ ArtToken.sol # Standard non-upgradeable ArtToken contract
│ ├─ ArtTokenUpgradeable.sol # Upgradeable ArtToken contract
│ ├─ ArtTokenCore.sol # Core token functionality implementation
│ ├─ archive/ # Archived contract versions
│ ├─ interfaces/ # Contract interfaces
│ │ └─ IArtToken.sol
│ └─ libraries/ # Utility libraries
│ └─ FixedPointMathLib.sol
├─ deploy/ # Deployment scripts
├─ test/ # Test files
├─ docs/ # Technical documentation
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