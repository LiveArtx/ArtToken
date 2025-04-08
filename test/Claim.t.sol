// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

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

    function test_should_vest_correctly_over_entire_period_after_cliff_claimed() public {
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
        uint256 remainingDays = totalDays - (artTokenContract.CLIFF() / SECONDS_PER_DAY);

        // Check each day after cliff
        for (uint256 day = 1; day <= remainingDays; day++) {
            vm.warp(lastClaimTime + SECONDS_PER_DAY);
            
            uint256 newClaimable = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
            console.log(
                "Day %s: New Claimable: %s ETH, Already Claimed: %s ETH", 
                day, 
                newClaimable / 1e18, 
                totalClaimed / 1e18
            );
            
            // Skip if nothing new to claim
            if (newClaimable == 0) continue;

            // Claim and verify
            uint256 preClaimTotal = totalClaimed;
            artTokenContract.claim(allocatedAmount, merkleProof);
            totalClaimed += newClaimable;

            // Verify the math
            assert(preClaimTotal + newClaimable == totalClaimed);
            
            lastClaimTime = block.timestamp;
        }

        // Verify final amounts
        assertApproxEqAbs(
            totalClaimed, 
            allocatedAmount, 
            remainingDays, // Total accumulated rounding error allowance
            "Final claimed amount should equal allocated amount"
        );

        console.log("--------------------------------");
        console.log(
            "Remaining Claimable: %s ETH", 
            artTokenContract.getClaimableAmount(claimer1, allocatedAmount) / 1e18
        );
        console.log("Total Claimed: %s ETH", totalClaimed / 1e18);
        console.log("Balance of claimer1: %s ETH", artTokenContract.balanceOf(claimer1) / 1e18);
        vm.stopPrank();
    }

    function test_should_vest_correctly_every_10_days_over_entire_period() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        uint256 startTime = block.timestamp;
        _setVestingStartTime(startTime);

        uint256 totalClaimed = 0;
        uint256 lastClaimTime = startTime;
        uint256 SECONDS_PER_DAY = 1 days;
        uint256 totalDays = artTokenContract.DURATION() / SECONDS_PER_DAY;

        uint256 increment = 10;
        vm.startPrank(claimer1);

        for (uint256 day = 0; day < totalDays; day += increment) {
            
           
            
            uint256 newClaimable = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
            console.log(
                "Day %s: Claimable Amount: %s ETH, Already Claimed: %s ETH", 
                day, 
                newClaimable / 1e18, 
                totalClaimed / 1e18
            );

            if (newClaimable > 0) {
                artTokenContract.claim(allocatedAmount, merkleProof);
                totalClaimed += newClaimable;
            }

            increment = (day + 10 > totalDays) ? (totalDays - day) : 10;
            vm.warp(lastClaimTime + (increment * SECONDS_PER_DAY));
            lastClaimTime += (increment * SECONDS_PER_DAY);
        }

        // Check final day claimable before claiming
        vm.warp(startTime + artTokenContract.DURATION());
        uint256 finalClaimable = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);
        console.log(
            "Final Day %s: Claimable Amount: %s ETH, Already Claimed: %s ETH", 
            totalDays, 
            finalClaimable / 1e18, 
            totalClaimed / 1e18
        );

        // Claim the final amount after the vesting period has ended
        vm.warp(startTime + artTokenContract.DURATION() + 1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed += finalClaimable;

        console.log("--------------------------------");
        console.log(
            "Remaining Claimable: %s ETH", 
            artTokenContract.getClaimableAmount(claimer1, allocatedAmount) / 1e18
        );

        console.log("Total Claimed: %s ETH", totalClaimed / 1e18);
        console.log("Balance of claimer1: %s ETH", artTokenContract.balanceOf(claimer1) / 1e18);
        vm.stopPrank();

        assertEq(totalClaimed, allocatedAmount);
        assertEq(artTokenContract.balanceOf(claimer1), totalClaimed);
    }

    function test_should_claim_total_amount_after_vesting_period_ends() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        _setVestingStartTime(block.timestamp - 1);

        vm.warp(artTokenContract.vestingStart() + artTokenContract.DURATION() + 1);

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        assertEq(artTokenContract.getClaimedAmount(claimer1), allocatedAmount);
        assertEq(artTokenContract.balanceOf(claimer1), allocatedAmount);
    }

    function test_should_claim_during_cliff_and_after_vesting_ends_only() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        _setVestingStartTime(block.timestamp - 1);

        uint256 cliffAmount = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        assertEq(artTokenContract.getClaimedAmount(claimer1), cliffAmount);
        assertEq(artTokenContract.balanceOf(claimer1), cliffAmount);

        vm.warp(artTokenContract.vestingStart() + artTokenContract.DURATION() + 1);

        uint256 finalClaimable = artTokenContract.getClaimableAmount(claimer1, allocatedAmount);

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        console.log(
            "Claimed after vesting ended: %s ETH", 
            finalClaimable / 1e18
        );

        assertEq(artTokenContract.getClaimedAmount(claimer1), allocatedAmount);
        assertEq(artTokenContract.balanceOf(claimer1), allocatedAmount);
    }
}