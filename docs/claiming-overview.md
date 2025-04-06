# ART Token Claiming System Overview

## Introduction
The ART token implements a sophisticated claiming system with two distinct claiming mechanisms and a vesting schedule. This document outlines the technical details of how tokens can be claimed and how the vesting schedule works.

## Vesting Schedule Parameters

- **Total Duration**: 180 days
- **Cliff Period**: 7 days
- **Initial Unlock**: 25% of allocation
- **Linear Vesting**: 75% over 173 days (post-cliff)
- **Maximum Supply**: 1,000,000,000 tokens (18 decimals)

## Claiming Mechanisms

### 1. Standard Claim Process (`claim`)
Users can claim their tokens directly through the standard claiming process:

```solidity
function claim(uint256 totalAllocation, bytes32[] calldata merkleProof)
```

#### Features:
- Follows vesting schedule
- Multiple claims allowed
- Requires valid Merkle proof
- Claims only available tokens based on time elapsed
- Automatically tracks claimed amounts

#### Process Flow:
1. User submits claim with their total allocation and Merkle proof
2. System verifies vesting has started
3. Validates Merkle proof against stored root
4. Calculates claimable amount based on vesting schedule
5. Mints tokens to user's address
6. Updates claimed amount tracking

### 2. Staking Contract Claim (`claimFor`)
Special claiming mechanism for the staking contract:

```solidity
function claimFor(uint256 allocatedAmount, bytes32[] calldata merkleProof, address receiver)
```

#### Features:
- One-time claim of full allocation
- Only callable by authorized staking contract
- Bypasses standard vesting schedule
- Requires valid Merkle proof
- Cannot be used if user has claimed through standard process

#### Process Flow:
1. Staking contract submits claim with allocation, proof, and receiver
2. System verifies staking contract authorization
3. Validates Merkle proof
4. Checks user hasn't claimed before
5. Mints full allocation to receiver
6. Marks allocation as fully claimed

## Vesting Calculation Details

The vesting calculation is handled by the `_calculateClaimable` function:

### Initial 25% Claim
- Available immediately after vesting starts
- One-time claim tracked by `initialClaimed` mapping
- Calculated as: `totalAllocation * 25 / 100`

### Linear Vesting (75%)
- Begins after 7-day cliff
- Uses precise fixed-point math for calculations
- Formula: `remaining * vestingElapsed / (DURATION - CLIFF)`
- Where:
  - `remaining = totalAllocation * 75 / 100`
  - `vestingElapsed = min(currentTime - cliffEnd, DURATION - CLIFF)`

## Security Features

1. **Merkle Proof Verification**
   - Ensures only authorized allocations can be claimed
   - Prevents unauthorized modifications to allocation amounts
   - Efficient verification of large distribution lists

2. **Time-based Controls**
   - Vesting start time must be reached before claims
   - Cliff period enforced for linear vesting
   - Maximum vesting duration enforced

3. **State Tracking**
   - Tracks claimed amounts per user
   - Prevents double-claiming of initial allocation
   - Maintains total users claimed counter

4. **Access Controls**
   - Staking contract address must be pre-authorized
   - Only owner can set critical parameters
   - Protected functions for contract management

5. **Safe Mathematics**
   - Uses `FixedPointMathLib` for precise calculations
   - Prevents overflow/underflow issues
   - Maintains precision in token calculations

## Important Considerations

1. **Claim Timing**
   - Users should consider gas costs when claiming frequently
   - Larger claims may be more cost-effective
   - Initial 25% can be claimed immediately after vesting starts

2. **Staking Integration**
   - Users planning to stake should coordinate with staking contract
   - Cannot use standard claim if tokens claimed through staking
   - Staking claims are all-or-nothing

3. **Verification**
   - Users should verify their allocation and Merkle proof before claiming
   - Merkle proofs can be verified off-chain before submission
   - Failed claims will still consume gas

## Events

The system emits events for important actions:
- `TokensClaimed(address indexed user, uint256 amount)`
- `SetClaimableSupply(uint256 amount)`

These events can be used to track claiming activity and system configuration changes.
