// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IArtTokenCore.sol";

/// @title ArtTokenCore - Core logic for ART token vesting and claims
/// @notice Manages token generation events (TGE), vesting schedules, and claims
/// @dev Uses Merkle proofs for claim verification and fixed-point math for calculations
abstract contract ArtTokenCore is IArtTokenCore {
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTANTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Number of decimal places for the token
    uint8 public constant DECIMALS = 18;

    /// @notice Duration of the Token Generation Event (TGE)
    uint256 public constant TGE_DURATION = 7 days;

    /// @notice Duration of the vesting period after TGE
    uint256 public constant VESTING_DURATION = 180 days;

    /// @notice Maximum supply of ART tokens
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ STORAGE ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Tracks the amount of tokens claimed by each user
    mapping(address => uint256) internal claimedAmount;

    /// @notice Stores claim details for each user
    mapping(address => Claim) internal claims;

    /// @notice Merkle root used for claim verification
    bytes32 public merkleRoot;

    /// @notice Total amount of tokens available for claims
    uint256 public claimableSupply;

    /// @notice Total amount of tokens burned
    uint256 public totalBurned;

    /// @notice Timestamp when TGE is enabled
    uint256 public tgeEnabledAt;

    /// @notice Number of unique users who have claimed tokens
    uint256 public totalUsersClaimed;

    /// @notice Address of the staking contract
    address public stakingContractAddress;

    /// @notice Percentage of tokens claimable at TGE
    uint256 public tgeClaimPercentage;


    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ GETTERS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Returns the current claimable supply
    /// @return uint256 The amount of claimable tokens
    function getClaimableSupply() public view returns (uint256) {
        return claimableSupply;
    }

    /// @notice Retrieves claim details for a specific address
    /// @param account The address of the user
    /// @return Claim struct containing claim details
    function claimDetailsByAccount(address account) external view returns (Claim memory) {
        return claims[account];
    }

    /// @notice Checks whether the TGE is currently active
    /// @return bool True if TGE is active, false otherwise
    function isTGEActive() public view returns (bool) {
        return tgeEnabledAt > 0 && block.timestamp >= tgeEnabledAt && block.timestamp <= tgeEnabledAt + TGE_DURATION;
    }

    /// @notice Returns the start and end timestamps for TGE and vesting periods
    /// @return tgeStart Start time of TGE
    /// @return tgeEnd End time of TGE
    /// @return vestingEnd End time of the vesting period
    function claimingPeriods() public view returns (uint256 tgeStart, uint256 tgeEnd, uint256 vestingEnd) {
        tgeStart = tgeEnabledAt;
        tgeEnd = tgeStart + TGE_DURATION;
        vestingEnd = tgeEnd + VESTING_DURATION;
    }

    /// @notice Calculates the daily release amount during vesting
    /// @param _allocatedAmount Total allocated tokens for the user
    /// @param _claimed Amount already claimed by the user
    /// @return uint256 Amount that can be claimed per day
    function calculateDailyRelease(uint256 _allocatedAmount, uint256 _claimed) public pure returns (uint256) {
        uint256 remaining = _allocatedAmount - _claimed;
        uint256 vestingCliff = 180; // days
        return FixedPointMathLib.mulDivDown(remaining, 1e18, uint256(vestingCliff) * 1e18);
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ HELPER FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /// @notice Verifies a Merkle proof for a claim
    /// @param claimer Address of the claimant
    /// @param allocatedAmount Amount allocated to the claimer
    /// @param merkleProof Proof verifying the claim
    function verifyMerkleProof(address claimer, uint256 allocatedAmount, bytes32[] calldata merkleProof) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, allocatedAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
    }

    /// @notice Calculates the claimable amount based on vesting schedules
    /// @param claimer Address of the claimant
    /// @param allocatedAmount Total allocated tokens for the user
    /// @return releaseAmount Amount that can be claimed in the current cycle
    function calculateReleaseAmount(address claimer, uint256 allocatedAmount) internal returns (uint256 releaseAmount) {
        Claim storage userClaim = claims[claimer];

        // After vesting period, claim all remaining tokens
        (,, uint256 vestingEnd) = claimingPeriods();
        if (block.timestamp >= vestingEnd) {
            return allocatedAmount - userClaim.claimed;
        }

        // During TGE period
        if (isTGEActive()) {
            require(!userClaim.claimedAtTGE, "Already claimed TGE amount");
            uint256 tgeAmount = FixedPointMathLib.mulWadUp(allocatedAmount, formatToE18(tgeClaimPercentage));
            userClaim.dailyRelease = calculateDailyRelease(allocatedAmount, tgeAmount);
            return tgeAmount;
        }

        // During vesting period
        require(userClaim.lastClaimed + 1 days <= block.timestamp, "Claim only once per day");
        if (userClaim.dailyRelease == 0) {
            userClaim.dailyRelease = calculateDailyRelease(allocatedAmount, userClaim.claimed);
            return userClaim.dailyRelease;
        } else {
            return userClaim.dailyRelease;
        }
    }

    /// @notice Formats a percentage value to a fixed-point 18-decimal representation
    /// @param percentage The percentage value (1-100)
    /// @return uint256 The percentage scaled to 18 decimals
    function formatToE18(uint256 percentage) internal pure returns (uint256) {
        require(percentage >= 1 && percentage <= 100, "Value must be between 1 and 100");
        return (percentage * 1e18) / 100;
    }
}
