// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";
import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IArtTokenCore} from "contracts/interfaces/IArtTokenCore.sol";

contract ArtTokenUpgradeable_Claim is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_merkle_proof_is_invalid() public {
        _setVestingStartTime(block.timestamp - 1);

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid Merkle proof");
        artTokenContractUpgradeable.claim(CLAIM_AMOUNT, new bytes32[](0));
        vm.stopPrank();
    }

    function test_should_revert_when_vesting_has_not_started() public {
        _setVestingStartTime(block.timestamp + 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.expectRevert("Vesting has not started");

        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
    }

    function test_should_revert_when_user_has_claimed_already_during_cliff() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the TGE enabled at to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Nothing to claim");
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_attempting_to_claim_multiple_times_per_day() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the cliff period to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        // warp to end of cliff period
        vm.warp(block.timestamp + artTokenContractUpgradeable.CLIFF());

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Nothing to claim");
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_release_amount_is_greater_than_claimable_supply() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the vesting start time to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        uint256 expectedClaimAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);

        uint256 remainingMintableSupply = artTokenContractUpgradeable.cap() - artTokenContractUpgradeable.totalSupply();

        _mintTokens(deployer, remainingMintableSupply);

        uint256 currentSupply = artTokenContractUpgradeable.totalSupply();
        uint256 maxSupply = artTokenContractUpgradeable.cap();

        // claim the tokens - this should exceed the cap
        vm.startPrank(claimer1);
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, currentSupply + expectedClaimAmount, maxSupply));
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
    }

     function test_should_update_claimedAmount_after_claim() public {
        _setVestingStartTime(block.timestamp - 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 expectedClaimAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);

        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), expectedClaimAmount);
     }

    function test_should_cap_vestingElapsed_at_max_duration() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set vesting start time far in the past to exceed DURATION - CLIFF
        _setVestingStartTime(block.timestamp - artTokenContractUpgradeable.DURATION());

        // Calculate expected claim amount when fully vested (after cliff)
        uint256 expectedClaimAmount = allocatedAmount;

        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        // Verify claimed amount equals full allocation
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), expectedClaimAmount);
    }

    function test_should_emit_TokensClaimed_event() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the vesting start time to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        uint256 expectedClaimAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        // Expect the TokensClaimed event with correct parameters
        vm.expectEmit(true, true, true, true);
        emit IArtTokenCore.TokensClaimed(claimer1, expectedClaimAmount);
        
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
    }

    function test_should_release_correct_amounts_at_different_vesting_stages() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set vesting start time
        _setVestingStartTime(block.timestamp);

        // Test initial claim during cliff period
        vm.startPrank(claimer1);
        uint256 cliffAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), cliffAmount);
        uint256 totalClaimed = cliffAmount;

        // Test claim at 50% of vesting period
        vm.warp(block.timestamp + artTokenContractUpgradeable.CLIFF() + (artTokenContractUpgradeable.DURATION() - artTokenContractUpgradeable.CLIFF()) / 2);
        uint256 halfwayAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        totalClaimed += halfwayAmount;
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), totalClaimed);

        // Test final claim at end of vesting
        vm.warp(block.timestamp + artTokenContractUpgradeable.DURATION());
        uint256 finalAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        totalClaimed += finalAmount;
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), totalClaimed);
        assertEq(totalClaimed, allocatedAmount); // Verify full amount was claimed
        vm.stopPrank();
    }

    function test_should_update_user_balance_after_claim() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        _setVestingStartTime(block.timestamp - 1);
        
        uint256 initialBalance = artTokenContractUpgradeable.balanceOf(claimer1);
        uint256 expectedClaimAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        uint256 finalBalance = artTokenContractUpgradeable.balanceOf(claimer1);
        assertEq(finalBalance - initialBalance, expectedClaimAmount);
    }

    function test_should_handle_claims_near_vesting_boundaries() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Test claim exactly at cliff end
        _setVestingStartTime(block.timestamp - artTokenContractUpgradeable.CLIFF());
        
        vm.startPrank(claimer1);
        uint256 cliffEndAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), cliffEndAmount);
        uint256 totalClaimed = cliffEndAmount;

        // Test claim one second before vesting ends
        vm.warp(block.timestamp + artTokenContractUpgradeable.DURATION() - artTokenContractUpgradeable.CLIFF() - 1);
        uint256 nearEndAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        totalClaimed += nearEndAmount;
        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), totalClaimed);
        vm.stopPrank();
    }

    function test_should_vest_correctly_over_entire_period() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set vesting start time
        _setVestingStartTime(block.timestamp);
        
        uint256 totalClaimed = 0;
        uint256 lastClaimTime = block.timestamp;
        uint256 SECONDS_PER_DAY = 1 days;
        uint256 totalDays = artTokenContractUpgradeable.DURATION() / SECONDS_PER_DAY;

        vm.startPrank(claimer1);

        // Test initial cliff amount
        uint256 cliffAmount = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
        assertEq(cliffAmount, FixedPointMathLib.mulWadDown(allocatedAmount, 0.25e18), "Incorrect cliff amount");
        
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        totalClaimed = cliffAmount;

        // Skip cliff period
        vm.warp(block.timestamp + artTokenContractUpgradeable.CLIFF());
        lastClaimTime = block.timestamp;

        // Calculate expected daily vesting amount after cliff
        uint256 remainingAmount = allocatedAmount - cliffAmount;
        uint256 remainingDays = totalDays - (artTokenContractUpgradeable.CLIFF() / SECONDS_PER_DAY);
        uint256 expectedDailyVesting = remainingAmount / remainingDays;

        // Check each day after cliff
        for (uint256 day = 1; day <= remainingDays; day++) {
            vm.warp(lastClaimTime + SECONDS_PER_DAY);
            
            uint256 newClaimable = artTokenContractUpgradeable.getClaimableAmount(claimer1, allocatedAmount);
            // console.log("Day %s: New Claimable: %s, Total Claimed: %s", day, newClaimable, totalClaimed);
            
            // Skip if nothing new to claim
            if (newClaimable == 0) continue;

            // Claim and verify
            artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
            totalClaimed += newClaimable;
            
            // Allow for 1 wei rounding error per day
            assertApproxEqAbs(
                newClaimable, 
                expectedDailyVesting, 
                day, // Accumulating rounding error allowance
                string.concat("Day ", vm.toString(day), ": Incorrect daily vesting amount")
            );
            
            uint256 actualClaimed = artTokenContractUpgradeable.getClaimedAmount(claimer1);
            assertEq(
                actualClaimed, 
                totalClaimed, 
                string.concat("Day ", vm.toString(day), ": Incorrect total claimed amount")
            );
            
            lastClaimTime = block.timestamp;
        }

        // Verify final amounts
        assertApproxEqAbs(
            totalClaimed, 
            allocatedAmount, 
            remainingDays, // Total accumulated rounding error allowance
            "Final claimed amount should equal allocated amount"
        );
        vm.stopPrank();
    }
}