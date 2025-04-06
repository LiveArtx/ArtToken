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

    /// @dev Calculate how much the user can currently claim
    /// @param user The address of the user claiming tokens
    /// @param totalAllocation The total token allocation for the user from Merkle tree
    /// @param processClaim Whether to process the claim or not
    /// @return The amount of tokens that can be claimed in the current transaction
    function _calculateClaimable(address user, uint256 totalAllocation, bool processClaim) internal returns (uint256) {
        // Calculate time passed since vesting started
        uint256 elapsed = block.timestamp - vestingStart;
        uint256 vested = 0;

        // Initial claim: 25% of total allocation is available immediately
        if (!initialClaimed[user]) {
            vested += (totalAllocation * CLIFF_PERCENTAGE) / 100;
        }

        // Linear vesting calculation for remaining 75% of tokens
        // Only starts after the 7-day cliff period
        if (elapsed > CLIFF) {
            // Calculate how much time has passed since the cliff
            uint256 vestingElapsed = elapsed - CLIFF;
            
            // The vesting schedule has a maximum duration (180 days total, or DURATION constant)
            // If more time has passed than the vesting duration, we cap it to prevent over-vesting
            // Example: 
            // - Total duration is 180 days, cliff is 7 days
            // - Linear vesting happens over (180 - 7) = 173 days
            // - If user claims after 200 days, we treat it as if only 173 days passed because:
            //   1. The vesting schedule is designed to release 100% of tokens by day 180
            //   2. First 7 days (cliff period) no linear vesting occurs
            //   3. The remaining 75% of tokens vest linearly over days 7-180 (173 days)
            //   4. After day 180, users should not receive more tokens than their total allocation
            //   5. Therefore, we cap the elapsed time to 173 days to ensure exact 100% vesting
            if (vestingElapsed > (DURATION - CLIFF)) {
                vestingElapsed = DURATION - CLIFF;
            }

            // Calculate remaining 75% using FixedPointMathLib
            // This is the portion that will vest linearly after the cliff
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
            // 4. Gas efficient computation in a single operation
            uint256 linearVested = FixedPointMathLib.mulDivDown(remaining, vestingElapsed, DURATION - CLIFF);

            // At the end of vesting period, ensure we get exactly the remaining amount
            // This prevents rounding errors from causing us to fall short of 100%
            if (vestingElapsed == DURATION - CLIFF) {
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

        // This condition means:
        // "If user hasn't claimed their 25% yet AND enough tokens are vested to cover the 25%"
        if (!initialClaimed[user] && vested >= (totalAllocation * CLIFF_PERCENTAGE) / 100) {
            if (processClaim) {
                initialClaimed[user] = true;
                totalUsersClaimed++;
            }
        }

        // If the user has more vested tokens than what they have already claimed,
        // calculate the difference as their claimable amount
        if (vested > alreadyClaimed) {
            claimable = vested - alreadyClaimed;
        }

        return claimable;
    }
}
