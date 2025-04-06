// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.28;

import {ArtToken} from "contracts/ArtToken.sol";
import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IArtTokenCore} from "contracts/interfaces/IArtTokenCore.sol";
import {console} from "forge-std/console.sol";

contract ArtToken_Claim is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_merkle_proof_is_invalid() public {
        _setVestingStartTime(block.timestamp - 1);

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid Merkle proof");
        artTokenContract.claim(CLAIM_AMOUNT, new bytes32[](0));
        vm.stopPrank();
    }

    function test_should_revert_when_vesting_has_not_started() public {
        _setVestingStartTime(block.timestamp + 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.expectRevert("Vesting has not started");

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
    }

    function test_should_revert_when_user_has_claimed_already_during_cliff() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the TGE enabled at to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Nothing to claim");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_attempting_to_claim_multiple_times_per_day() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the cliff period to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        // warp to end of cliff period
        vm.warp(block.timestamp + artTokenContract.CLIFF());

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Nothing to claim");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_release_amount_is_greater_than_claimable_supply() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the vesting start time to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        uint256 expectedClaimAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        uint256 remainingMintableSupply = artTokenContract.cap() - artTokenContract.totalSupply();

        _mintTokens(deployer, remainingMintableSupply);

        uint256 currentSupply = artTokenContract.totalSupply();
        uint256 maxSupply = artTokenContract.cap();

        // claim the tokens - this should exceed the cap
        vm.startPrank(claimer1);
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, currentSupply + expectedClaimAmount, maxSupply));
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

     function test_should_update_claimedAmount_after_claim() public {
        _setVestingStartTime(block.timestamp - 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 expectedClaimAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        assertEq(artTokenContract.getClaimedAmount(claimer1), expectedClaimAmount);
     }

    function test_should_cap_vestingElapsed_at_max_duration() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set vesting start time far in the past to exceed DURATION - CLIFF
        _setVestingStartTime(block.timestamp - artTokenContract.DURATION());

        // Calculate expected claim amount when fully vested (after cliff)
        uint256 expectedClaimAmount = allocatedAmount;

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        // Verify claimed amount equals full allocation
        assertEq(artTokenContract.getClaimedAmount(claimer1), expectedClaimAmount);
    }

    function test_should_emit_TokensClaimed_event() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the vesting start time to a time in the past
        _setVestingStartTime(block.timestamp - 1);

        uint256 expectedClaimAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        // Expect the TokensClaimed event with correct parameters
        vm.expectEmit(true, true, true, true);
        emit IArtTokenCore.TokensClaimed(claimer1, expectedClaimAmount);
        
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
    }

    function test_should_release_correct_amounts_at_different_vesting_stages() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set vesting start time
        uint256 startTime = block.timestamp;
        _setVestingStartTime(startTime);

        // Test initial claim during cliff period (25%)
        vm.startPrank(claimer1);
        uint256 cliffAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContract.claim(allocatedAmount, merkleProof);
        assertEq(artTokenContract.getClaimedAmount(claimer1), cliffAmount);
        uint256 totalClaimed = cliffAmount;

        // Move to halfway point of linear vesting period (after cliff)
        uint256 linearVestingDuration = artTokenContract.DURATION() - artTokenContract.CLIFF();
        vm.warp(startTime + artTokenContract.CLIFF() + (linearVestingDuration / 2));
        
        uint256 halfwayAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed += halfwayAmount;
        assertEq(artTokenContract.getClaimedAmount(claimer1), totalClaimed);

        // Move to end of full vesting period
        vm.warp(startTime + artTokenContract.DURATION());
        
        uint256 finalAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed += finalAmount;
        assertEq(artTokenContract.getClaimedAmount(claimer1), totalClaimed);
        assertEq(totalClaimed, allocatedAmount);
        vm.stopPrank();
    }

    function test_should_update_user_balance_after_claim() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        _setVestingStartTime(block.timestamp - 1);
        
        uint256 initialBalance = artTokenContract.balanceOf(claimer1);
        uint256 expectedClaimAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        uint256 finalBalance = artTokenContract.balanceOf(claimer1);
        assertEq(finalBalance - initialBalance, expectedClaimAmount);
    }

    function test_should_handle_claims_near_vesting_boundaries() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Test claim exactly at cliff end
        _setVestingStartTime(block.timestamp - artTokenContract.CLIFF());
        
        vm.startPrank(claimer1);
        uint256 cliffEndAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContract.claim(allocatedAmount, merkleProof);
        assertEq(artTokenContract.getClaimedAmount(claimer1), cliffEndAmount);
        uint256 totalClaimed = cliffEndAmount;

        // Test claim one second before vesting ends
        vm.warp(block.timestamp + artTokenContract.DURATION() - artTokenContract.CLIFF() - 1);
        uint256 nearEndAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed += nearEndAmount;
        assertEq(artTokenContract.getClaimedAmount(claimer1), totalClaimed);
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
        uint256 totalDays = artTokenContract.DURATION() / SECONDS_PER_DAY;

        vm.startPrank(claimer1);

        // Test initial cliff amount
        uint256 cliffAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        assertEq(cliffAmount, FixedPointMathLib.mulWadDown(allocatedAmount, 0.25e18), "Incorrect cliff amount");
        
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed = cliffAmount;

        // Skip cliff period
        vm.warp(block.timestamp + artTokenContract.CLIFF());
        lastClaimTime = block.timestamp;

        // Calculate expected daily vesting amount after cliff
        uint256 remainingAmount = allocatedAmount - cliffAmount;
        uint256 remainingDays = totalDays - (artTokenContract.CLIFF() / SECONDS_PER_DAY);
        uint256 expectedDailyVesting = remainingAmount / remainingDays;

        // Check each day after cliff
        for (uint256 day = 1; day <= remainingDays; day++) {
            vm.warp(lastClaimTime + SECONDS_PER_DAY);
            
            uint256 newClaimable = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
            console.log(
                "Day %s: New Claimable: %s ETH, Total Claimed: %s ETH", 
                day, 
                newClaimable / 1e18, 
                totalClaimed / 1e18
            );
            
            // Skip if nothing new to claim
            if (newClaimable == 0) continue;

            // Claim and verify
            artTokenContract.claim(allocatedAmount, merkleProof);
            totalClaimed += newClaimable;
            
            // Allow for 1 wei rounding error per day
            assertApproxEqAbs(
                newClaimable, 
                expectedDailyVesting, 
                day, // Accumulating rounding error allowance
                string.concat("Day ", vm.toString(day), ": Incorrect daily vesting amount")
            );
            
            uint256 actualClaimed = artTokenContract.getClaimedAmount(claimer1);
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