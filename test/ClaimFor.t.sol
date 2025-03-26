// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ArtToken} from "contracts/non-upgradable/layer-zero/ArtToken.sol";
import {StakingMock} from "contracts/mocks/StakingMock.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import "forge-std/Console.sol";

contract ArtToken_ClaimFor is ContractUnderTest {
    StakingMock stakingMock;

    function setUp() public virtual override{
        ContractUnderTest.setUp();
        stakingMock = new StakingMock();
    }

    function test_should_revert_when_staking_contract_is_not_set() public {
         uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(claimer1);
        vm.expectRevert("Staking contract not set");
        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_revert_when_staking_contract_is_set_invalid() public {
        _setStakingContract(address(stakingMock));

         uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid staking contract address");
        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_revert_when_merkle_root_is_invalid() public {
        _setStakingContract(address(stakingMock));

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        vm.expectRevert("Invalid merkle proof");
        artTokenContract.claimFor(allocatedAmount, new bytes32[](0), claimer1);
    }

    function test_should_revert_when_already_claimed() public {
        _setStakingContract(address(stakingMock));
        (, bytes32[] memory merkleProof) = _claimerDetails(); 

         vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        // initial claim
        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);

        // perform second claim
        vm.expectRevert("User already claim");
        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_revert_when_releaseAmount_exceeds_claimable_supply() public {
        _setStakingContract(address(stakingMock));
        _setClaimableSupply(100 wei);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        vm.expectRevert("Insufficient claimable supply");
        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_update_user_claim_details() public {
        _setStakingContract(address(stakingMock));

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);

        ArtToken.Claim memory claimDetails = artTokenContract.claimDetailsByAccount(claimer1);

        assertEq(claimDetails.amount, allocatedAmount);
        assertEq(claimDetails.claimed, allocatedAmount);
        assertEq(claimDetails.lastClaimed, block.timestamp);
        assertEq(claimDetails.dailyRelease, 0);
        assertEq(claimDetails.claimedAtTGE, false);
    }

    function test_should_update_totalUsersClaimed_counter() public {
        _setStakingContract(address(stakingMock));

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        artTokenContract.claimFor(allocatedAmount, merkleProof, claimer1);
        assertEq(artTokenContract.totalUsersClaimed(), 1);
    }

   

}