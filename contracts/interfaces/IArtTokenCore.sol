// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title IArtTokenCore - Interface for the ART token core logic
/// @notice Defines the necessary methods for ART token vesting and claims
/// @dev Uses Merkle proofs for claim verification and fixed-point math for calculations
interface IArtTokenCore {
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTANTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Number of decimal places for the token
    function DECIMALS() external view returns (uint8);

    /// @notice Duration of the Token Generation Event (TGE)
    function TGE_DURATION() external view returns (uint256);

    /// @notice Duration of the vesting period after TGE
    function VESTING_DURATION() external view returns (uint256);

    /// @notice Maximum supply of ART tokens
    function MAX_SUPPLY() external view returns (uint256);

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ STRUCTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Represents a user's claim status
    struct Claim {
        uint256 amount;         // Total allocated amount
        uint256 claimed;        // Amount already claimed
        uint256 lastClaimed;    // Timestamp of the last claim
        uint256 dailyRelease;   // Daily vested amount
        bool claimedAtTGE;      // Whether TGE claim has been made
    }

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

    /// @notice Retrieves claim details for a specific address
    /// @param account The address of the user
    /// @return Claim struct containing claim details
    function claimDetailsByAccount(address account) external view returns (Claim memory);

    /// @notice Checks whether the TGE is currently active
    /// @return bool True if TGE is active, false otherwise
    function isTGEActive() external view returns (bool);

    /// @notice Returns the start and end timestamps for TGE and vesting periods
    /// @return tgeStart Start time of TGE
    /// @return tgeEnd End time of TGE
    /// @return vestingEnd End time of the vesting period
    function claimingPeriods() external view returns (uint256 tgeStart, uint256 tgeEnd, uint256 vestingEnd);
}
