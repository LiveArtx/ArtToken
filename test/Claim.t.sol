// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ArtToken} from "contracts/non-upgradable/layer-zero/ArtToken.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";

contract ArtToken_Constructor is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_claim_after_vesting_period() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();
        (,,uint256 vestingEnd) = artTokenContract.claimingPeriods();

        // Set the TGE enabled at to a time in the past
        vm.startPrank(deployer);
        artTokenContract.setTgeEnabledAt(block.timestamp - 1);
        vm.stopPrank();

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
        vm.startPrank(deployer);
        artTokenContract.setTgeEnabledAt(block.timestamp - 1);
        vm.stopPrank();

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

        vm.startPrank(deployer);
        // reduce the claimable supply
        artTokenContract.setClaimableSupply(100 wei);

        // Set the TGE enabled at to a time in the past
        artTokenContract.setTgeEnabledAt(block.timestamp - 1);
        vm.stopPrank();

        // warp to end of TGE period
        vm.warp(block.timestamp + tgeEnd);

        // claim the tokens
        vm.startPrank(claimer1);
        vm.expectRevert("Insufficient claimable supply");
        artTokenContract.claim(allocatedAmount, merkleProof);
    }
}