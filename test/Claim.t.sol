// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtTokenNonUpgradeable.sol";
import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import "forge-std/Console.sol";

contract ArtToken_Claim is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_merkle_proof_is_invalid() public {
        _setTgeEnabledAt(block.timestamp - 1);

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid merkle proof");
        artTokenContract.claim(CLAIM_AMOUNT, new bytes32[](0));
        vm.stopPrank();
    }

    function test_should_revert_when_TGE_is_not_enabled() public {
         uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.expectRevert("TGE not enabled");

        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
    }

    function test_should_revert_when_user_has_claimed_already_during_TGE() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the TGE enabled at to a time in the past
        _setTgeEnabledAt(block.timestamp - 1);

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Already claimed TGE amount");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_attempting_to_claim_multiple_times_per_day() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (,uint256 tgeEnd,) = artTokenContract.claimingPeriods();
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Set the TGE enabled at to a time in the past
        vm.startPrank(deployer);
        artTokenContract.setTgeEnabledAt(block.timestamp - 1);
        vm.stopPrank();

        // warp to end of TGE period
        vm.warp(block.timestamp + tgeEnd);

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);

        // Attempt to claim the tokens for a second time
        vm.expectRevert("Claim only once per day");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

    function test_should_revert_when_release_amount_is_greater_than_claimable_supply() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (,uint256 tgeEnd,) = artTokenContract.claimingPeriods();
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // reduce the claimable supply
        _setClaimableSupply(100 wei);

        // Set the TGE enabled at to a time in the past
        _setTgeEnabledAt(block.timestamp - 1);

        // warp to end of TGE period
        vm.warp(block.timestamp + tgeEnd);

        // claim the tokens
        vm.startPrank(claimer1);
        vm.expectRevert("Insufficient claimable supply");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }

     function test_should_update_user_claim_details_during_TGE_claim() public {
         _setTgeEnabledAt(block.timestamp - 1);

         assertTrue(artTokenContract.isTGEActive());

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 expectedTgeReleaseAmount = FixedPointMathLib.mulWadDown(allocatedAmount, 0.25e18);
        uint256 dailyReleaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, expectedTgeReleaseAmount);

        artTokenContract.claim(allocatedAmount, merkleProof);

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, expectedTgeReleaseAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetails.claimedAtTGE, true);

        // User Balance
        assertEq(artTokenContract.balanceOf(claimer1), expectedTgeReleaseAmount);
    }


     function test_should_update_user_claim_details_after_a_tge_and_vesting_claim() public {
        _setTgeEnabledAt(block.timestamp - 1);

         assertTrue(artTokenContract.isTGEActive());

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 expectedTgeReleaseAmount = FixedPointMathLib.mulWadDown(allocatedAmount, 0.25e18);
        uint256 dailyReleaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, expectedTgeReleaseAmount);

        artTokenContract.claim(allocatedAmount, merkleProof);

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, expectedTgeReleaseAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetails.claimedAtTGE, true);

        // User Balance
        assertEq(artTokenContract.balanceOf(claimer1), expectedTgeReleaseAmount);

        // Ensure we are in the vesting window.
        (, uint256 tgeEnd, uint256 vestingEnd) = artTokenContract.claimingPeriods();
        vm.warp(tgeEnd + 5 days);
        assert(block.timestamp > tgeEnd && block.timestamp < vestingEnd);


        vm.startPrank(address(claimer1));
        uint256 releaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, expectedTgeReleaseAmount);

        artTokenContract.claim(allocatedAmount, merkleProof);

        ArtToken.Claim memory claimDetailsAfterVestingClaim = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetailsAfterVestingClaim.amount, allocatedAmount);
        assertEq(claimDetailsAfterVestingClaim.claimed, expectedTgeReleaseAmount + releaseAmount);
        assertEq(claimDetailsAfterVestingClaim.lastClaimed, block.timestamp);
        assertEq(claimDetailsAfterVestingClaim.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetailsAfterVestingClaim.claimedAtTGE, true);

        // User Balance
        assertEq(artTokenContract.balanceOf(claimer1), expectedTgeReleaseAmount + releaseAmount);
    }

     function test_should_update_user_claim_details_during_vesting_claim_only() public {
         _setTgeEnabledAt(block.timestamp - 1);

        // Ensure we are in the vesting window.
        (, uint256 tgeEnd, uint256 vestingEnd) = artTokenContract.claimingPeriods();
        vm.warp(tgeEnd + 5 days);
        assert(block.timestamp > tgeEnd && block.timestamp < vestingEnd);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 dailyReleaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, 0);

        artTokenContract.claim(allocatedAmount, merkleProof);

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, dailyReleaseAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetails.claimedAtTGE, false);

        // User Balance
        assertEq(artTokenContract.balanceOf(claimer1), dailyReleaseAmount);
    }

      function test_should_update_user_balance_after_claiming_everyday_during_vesting_only() public {
         _setTgeEnabledAt(block.timestamp - 1);

        // Ensure we are in the vesting window.
        (, uint256 tgeEnd, ) = artTokenContract.claimingPeriods();
        vm.warp(tgeEnd + 1);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 dailyReleaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, 0);

        uint256 totalClaimed;

        // First claim at tgeEnd
        artTokenContract.claim(allocatedAmount, merkleProof);
        totalClaimed += dailyReleaseAmount;

        // Then loop for remaining days
        for(uint256 i = 2; i <= 180; i++) {
            vm.warp(tgeEnd + (i * 1 days));
            artTokenContract.claim(allocatedAmount, merkleProof);
            totalClaimed += dailyReleaseAmount;
        }

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertApproxEqAbs(claimDetails.claimed, totalClaimed, 100);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetails.claimedAtTGE, false);

        // User Balance (100 wei rounding loss)
        assertApproxEqAbs(artTokenContract.balanceOf(claimer1), totalClaimed, 100);
    }

    function test_should_update_user_claim_details_after_vesting_claim_only() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();
        (,,uint256 vestingEnd) = artTokenContract.claimingPeriods();

        // Set the TGE enabled at to a time in the past
        _setTgeEnabledAt(block.timestamp - 1);

        // warp to end of vesting period
        vm.warp(block.timestamp + vestingEnd);

        // claim the tokens
        vm.startPrank(claimer1);
        artTokenContract.claim(allocatedAmount, merkleProof);
        vm.stopPrank();

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, allocatedAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, 0);
        assertEq(claimDetails.claimedAtTGE, false);

        // assert the tokens were claimed
        assertEq(artTokenContract.balanceOf(claimer1), allocatedAmount);
    }

    function test_should_update_totalUsersClaimed_after_claim() public {
         _setTgeEnabledAt(block.timestamp - 1);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        artTokenContract.claim(allocatedAmount, merkleProof);
        assertEq(artTokenContract.totalUsersClaimed(), 1);
    }

   function test_should_run_successful_claims_across_all_periods() public {
        uint256 snapshotId;

        for (uint256 i = 1; i <= 100; i++) {
            snapshotId = vm.snapshot(); // Take a snapshot before modifying state

            _setTgeClaimPercentage(i);
            _executeFullCycleClaim(i);

            vm.revertTo(snapshotId); // Revert state to before this iteration
        }
    }

    function _executeFullCycleClaim(uint256 _tgeClaimPercentage) internal {

        _setTgeEnabledAt(block.timestamp - 1);

        assertTrue(artTokenContract.isTGEActive());

        uint256 allocatedAmount = CLAIM_AMOUNT; // 1000e18
        (, bytes32[] memory merkleProof) = _claimerDetails();

        // Debug prints or assertions
        console.log("TGE Percentage:", _tgeClaimPercentage);
        console.log("Allocated Amount:", allocatedAmount);
        
        // Calculate expected TGE amount step by step
        uint256 formattedPercentage = _formatToE18(_tgeClaimPercentage);
        console.log("Formatted Percentage:", formattedPercentage);
        
        uint256 expectedTgeReleaseAmount = FixedPointMathLib.mulWadDown(allocatedAmount, formattedPercentage);
        console.log("Expected TGE Release:", expectedTgeReleaseAmount);

        vm.startPrank(address(claimer1));
        
        // TGE Claim
        artTokenContract.claim(allocatedAmount, merkleProof);
        
        ArtToken.Claim memory afterTGE = artTokenContract.claimDetailsByAccount(claimer1);
        assertEq(afterTGE.claimed, expectedTgeReleaseAmount, "TGE claim amount incorrect");

        /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ VESTING CLAIM ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
        (, uint256 tgeEnd, uint256 vestingEnd ) = artTokenContract.claimingPeriods();
        vm.warp(tgeEnd + 1 days);

        // Calculate remaining amount after TGE
        uint256 remainingAmount = allocatedAmount - expectedTgeReleaseAmount;
        
        // Only do vesting claims if there's remaining amount
        if (remainingAmount > 0) {
            // Do two vesting period claims
            for(uint256 i; i < 2; i++){
                artTokenContract.claim(allocatedAmount, merkleProof);
                vm.warp(block.timestamp + 1 days);
            }
        }

        /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ POST VESTING CLAIM ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
        // Jump to vesting end
        vm.warp(vestingEnd);
        
        // Final claim
        artTokenContract.claim(allocatedAmount, merkleProof);

        ArtToken.Claim memory finalClaim = artTokenContract.claimDetailsByAccount(claimer1);
        
        // Final assertions
        assertEq(finalClaim.amount, allocatedAmount, "Final allocated amount incorrect");
        assertEq(finalClaim.claimed, allocatedAmount, "Final claimed amount should equal total allocation");
        assertEq(finalClaim.claimedAtTGE, true, "Should be marked as TGE claimed");
        assertEq(artTokenContract.balanceOf(claimer1), allocatedAmount, "Final balance should equal total allocation");
    }
}