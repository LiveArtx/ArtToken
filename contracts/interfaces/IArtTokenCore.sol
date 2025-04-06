// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title IArtTokenCore - Interface for the ART token core logic
/// @notice Defines the necessary methods for ART token vesting and claims
/// @dev Uses Merkle proofs for claim verification and fixed-point math for calculations
interface IArtTokenCore {
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTANTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Number of decimal places for the token
    function DECIMALS() external view returns (uint8);

    /// @notice Duration of the cliff period
    function CLIFF() external view returns (uint256);

    /// @notice Percentage of the cliff period
    function CLIFF_PERCENTAGE() external view returns (uint256);

    /// @notice Duration of the vesting period including the cliff period
    function DURATION() external view returns (uint256);

    /// @notice Maximum supply of ART tokens
    function MAX_SUPPLY() external view returns (uint256);

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ EVENTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Emitted when tokens are claimed
    /// @param user Address of the claimant
    /// @param amount Amount of tokens claimed
    event TokensClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when tokens are claimed and staked
    /// @param user Address of the claimant
    /// @param amount Amount of tokens staked
    event TokensClaimedAndStaked(address indexed user, uint256 amount);

    /// @notice Emitted when claimable supply is set
    /// @param amount New claimable supply
    event SetClaimableSupply(uint256 amount);

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ GETTERS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Returns the current claimable supply
    /// @return uint256 The amount of claimable tokens
    function getClaimableSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens claimed by a user
    /// @param user The address of the user
    /// @return uint256 The amount of tokens claimed
    function getClaimedAmount(address user) external view returns (uint256);

    /// @notice Returns the claimable amount for a user
    /// @param user The address of the user
    /// @param totalAllocation The total token allocation for the user from Merkle tree
    /// @return uint256 The amount of tokens that can be claimed in the current transaction
    function getClaimableAmount(address user, uint256 totalAllocation) external returns (uint256);
}
