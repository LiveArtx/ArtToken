// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IArtTokenCore.sol";

/// @title ArtTokenCore - Core logic for ART token vesting and claims
/// @notice Manages claimable tokens with cliff and linear vesting
/// @dev Uses Merkle proofs for claim verification and fixed-point math for calculations
abstract contract ArtTokenCore is IArtTokenCore {
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTANTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Number of decimal places for the token
    uint8 public constant DECIMALS = 18;

    /// @notice Duration of the cliff period
    uint256 public constant CLIFF = 7 days;

    /// @notice Percentage of the claimable supply that is available immediately
    uint256 public constant CLIFF_PERCENTAGE = 25;

    /// @notice Duration of the vesting period including the cliff period
    uint256 public constant DURATION = 180 days;

    /// @notice Maximum supply of ART tokens
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ STORAGE ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Tracks the amount of tokens claimed by each user
    mapping(address => uint256) internal claimedAmount;

    /// @notice Stores whether the user has claimed the initial amount
     mapping(address => bool) internal initialClaimed;

    /// @notice Merkle root used for claim verification
    bytes32 public merkleRoot;

    /// @notice Timestamp when vesting starts (including Cliff period)
    uint256 public vestingStart;

    /// @notice Total amount of tokens available for claims
    uint256 public claimableSupply;

    /// @notice Total amount of tokens burned
    uint256 public totalBurned;

    /// @notice Number of unique users who have claimed tokens
    uint256 public totalUsersClaimed;

    /// @notice Address of the staking contract
    address public stakingContractAddress;

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ GETTERS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Returns the current claimable supply
    /// @return uint256 The amount of claimable tokens
    function getClaimableSupply() public view returns (uint256) {
        return claimableSupply;
    }

    /// @notice Returns the amount of tokens claimed by a user
    /// @param user The address of the user
    /// @return uint256 The amount of tokens claimed
    function getClaimedAmount(address user) external view returns (uint256) {
        return claimedAmount[user];
    }

    /// @notice Returns the amount of tokens that can be claimed by a user
    /// @param user The address of the user
    /// @param totalAllocation The total token allocation for the user from Merkle tree
    /// @return uint256 The amount of tokens that can be claimed in the current transaction
    function getClaimableAmount(address user, uint256 totalAllocation) external returns (uint256) {
        return _calculateClaimable(user, totalAllocation, false);
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ HELPER FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @dev This function calculates how many tokens a user can claim right now
    /// SIMPLIFIED EXPLANATION:
    /// This is like a savings account that gradually unlocks your tokens over time:
    /// 1. Day 1: You get 25% of your tokens immediately
    /// 2. After 7 days: The remaining 75% starts unlocking gradually over 6 months
    /// 3. After 180 days: All your tokens are available
    ///
    /// Example with 1000 tokens:
    /// - Immediately: 250 tokens available (25%)
    /// - Over 173 days: The remaining 750 tokens unlock bit by bit
    /// - Each day after day 7, about 4.33 tokens become available (750/173, rounded down)
    /// - At day 180: All 1000 tokens are available (any rounding discrepancy is corrected at the end)
    function _calculateClaimable(address user, uint256 totalAllocation, bool processClaim) internal returns (uint256) {
        // Calculate time passed since vesting started
        uint256 elapsed = block.timestamp - vestingStart;
        uint256 vested = 0;

        // Initial 25% cliff allocation
        if (!initialClaimed[user]) {
            vested += (totalAllocation * CLIFF_PERCENTAGE) / 100;
        }

        // Linear vesting calculation for remaining 75% of tokens
        // Only starts after the 7-day cliff period
        if (elapsed > CLIFF) {
            // Calculate how much time has passed since the cliff
            uint256 vestingElapsed = elapsed - CLIFF;
            
            // Cap vesting at maximum duration (173 days of linear vesting)
            if (vestingElapsed >= (DURATION - CLIFF)) {
                vestingElapsed = DURATION - CLIFF;
            }

            // Calculate remaining 75% that vests linearly after the cliff
            // Example: If totalAllocation = 1000 tokens
            // - Cliff amount (25%) = 250 tokens (instant)
            // - Remaining amount (75%) = 750 tokens (linear)
            uint256 remaining = (totalAllocation * (100 - CLIFF_PERCENTAGE)) / 100;

            // Calculate linear vesting with precise division
            // mulDivDown performs: (remaining * vestingElapsed) / (DURATION - CLIFF) atomically
            // This ensures:
            // 1. No precision loss from separate multiplication and division
            // 2. No intermediate overflow even with large numbers
            // 3. Consistent rounding down behavior for partial amounts
            uint256 linearVested = FixedPointMathLib.mulDivDown(remaining, vestingElapsed, DURATION - CLIFF);

            // Ensure remaining amount at vesting end
            if (vestingElapsed >= DURATION - CLIFF) {
                linearVested = remaining;
            }

            // For subsequent claims (after initial claim), we need to include both:
            // 1. The cliff amount (25%)
            // 2. The linearly vested amount (based on time)
            // Example at 50% through linear vesting:
            // - If initialClaimed = true: vested = 25% + (75% * 0.5) = 62.5%
            // - If initialClaimed = false: vested = 25% + (75% * 0.5) = 62.5% (cliff added above)
            vested = initialClaimed[user] ? 
                (totalAllocation * CLIFF_PERCENTAGE) / 100 + linearVested : 
                vested + linearVested;
        }

        // Track how much the user has already claimed
        uint256 alreadyClaimed = claimedAmount[user];
        uint256 claimable = 0;

        // Track initial claim status
        if (!initialClaimed[user] && processClaim) {
            initialClaimed[user] = true;
            totalUsersClaimed++;
        }

        // Check if there are any unclaimed vested tokens available
        // vested = total tokens that should be available to the user at this moment
        // alreadyClaimed = total tokens the user has previously withdrawn
        // Example:
        //   Total allocation: 1000 tokens
        //   Currently vested: 400 tokens (25% cliff + some linear vesting)
        //   Already claimed: 250 tokens (previous withdrawals)
        //   Therefore claimable = 400 - 250 = 150 tokens
        if (vested > alreadyClaimed && block.timestamp <= vestingStart + DURATION) {
            // Calculate exact number of new tokens available for claiming
            // This ensures users can only claim the difference between
            // what's vested and what they've already taken out
            claimable = vested - alreadyClaimed;
        } else if (totalAllocation > alreadyClaimed && block.timestamp > vestingStart + DURATION) {
            // If the user has not claimed all their tokens by the end of the vesting period,
            // they can claim the remaining tokens
            claimable = totalAllocation - alreadyClaimed;
        }

        // If vested <= alreadyClaimed, claimable remains 0
        // This handles cases where:
        // 1. User has claimed everything available so far
        // 2. Not enough time has passed for new tokens to vest

        return claimable;
    }
}
