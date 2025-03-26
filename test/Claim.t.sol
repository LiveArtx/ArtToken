// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ArtToken} from "contracts/non-upgradable/layer-zero/ArtToken.sol";
import {FixedPointMathLib} from "contracts/lib/FixedPointMathLib.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";


contract ArtToken_Claim is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_claim_after_vesting_period() public {
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

        // assert the tokens were claimed
        assertEq(artTokenContract.balanceOf(claimer1), allocatedAmount);
    }

    function test_should_revert_when_merkle_proof_is_invalid() public {
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

        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        // User Details
        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, expectedTgeReleaseAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, dailyReleaseAmount);
        assertEq(claimDetails.claimedAtTGE, false);

        // User Balance
        assertEq(artTokenContract.balanceOf(claimer1), expectedTgeReleaseAmount);
    }

     function test_should_update_user_claim_details_after_vesting_claim_only() public {
         _setTgeEnabledAt(block.timestamp - 1);



        // Ensure we are in the vesting window.
         vm.warp(block.timestamp + 10 days);
        ( , uint256 tgeEnd, uint256 vestingEnd) = artTokenContract.claimingPeriods();
        assert(block.timestamp > tgeEnd && block.timestamp < vestingEnd);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;
        uint256 dailyReleaseAmount = artTokenContract.calculateDailyRelease(allocatedAmount, allocatedAmount);

        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);

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

    // Todo: tge claim, vesting claims till complete (180 days);

    function test_should_update_totalUsersClaimed_after_claim() public {
         _setTgeEnabledAt(block.timestamp - 1);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(claimer1));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
        assertEq(artTokenContract.totalUsersClaimed(), 1);
    }
}