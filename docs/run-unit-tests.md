# Running Unit Tests

## Testing Framework
The project uses Foundry as the primary testing framework. While the project includes Hardhat configuration, Foundry is the recommended testing framework for this project due to its superior performance and features.

## Prerequisites
- Foundry installed and configured
- Alchemy API key for forked network testing
- Node.js and Yarn (for coverage reporting)

## Running Tests

### Basic Test Execution
```bash
forge test --rpc-url https://base-mainnet.g.alchemy.com/v2/<ALCHEMY_KEY> --via-ir
```

### Coverage Reports
1. Set up environment:
```bash
export ALCHEMY_URL=""
```

2. Generate coverage report:
```bash
yarn coverage:build
```

3. View coverage report:
```bash
yarn coverage:view
```

## Test Structure
Tests are organized in the `test/` directory and follow Foundry's testing conventions. Each contract has its corresponding test file with comprehensive test cases covering all major functionality.

## Best Practices
- Run tests before making any significant changes
- Ensure all tests pass before submitting pull requests
- Maintain high test coverage for critical contract functions
- Use appropriate test fixtures and helper functions
