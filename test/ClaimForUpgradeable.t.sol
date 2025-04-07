// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.28;

import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";
import {StakingMock} from "./mocks/StakingMock.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import {IArtTokenCore} from "contracts/interfaces/IArtTokenCore.sol";

contract ArtTokenUpgradeable_ClaimFor is ContractUnderTest {
    StakingMock stakingMock;

    function setUp() public virtual override{
        ContractUnderTest.setUp();
        stakingMock = new StakingMock();
    }

    function test_should_revert_when_staking_contract_is_not_set() public {
         uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        _setVestingStartTime(block.timestamp - 1);

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid staking contract address");
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_revert_when_staking_contract_is_set_invalid() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

         uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(claimer1);
        vm.expectRevert("Invalid staking contract address");
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
    }

    function test_should_revert_when_merkle_root_is_invalid() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        vm.expectRevert("Invalid merkle proof");
        artTokenContractUpgradeable.claimFor(allocatedAmount, new bytes32[](0), claimer1);
    }

    function test_should_revert_when_already_claimed() public {
        _setVestingStartTime(block.timestamp - 1);
        _setStakingContract(address(stakingMock));
        
        (, bytes32[] memory merkleProof) = _claimerDetails(); 

         vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        // initial claim
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);

        // perform second claim
        vm.expectRevert("User already claimed");
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
    }


    function test_should_update_totalUsersClaimed_counter() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(stakingMock));
        uint256 allocatedAmount = CLAIM_AMOUNT;

        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
        assertEq(artTokenContractUpgradeable.totalUsersClaimed(), 1);
    }

     function test_should_update_claimedAmount_after_claim() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;

        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        vm.startPrank(address(stakingMock));
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
        vm.stopPrank();

        assertEq(artTokenContractUpgradeable.getClaimedAmount(claimer1), allocatedAmount);
     }


    function test_should_emit_TokensClaimed_event() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        vm.startPrank(address(stakingMock));
        
        vm.expectEmit(true, true, true, true);
        emit IArtTokenCore.TokensClaimed(claimer1, allocatedAmount);
        
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
        vm.stopPrank();
    }

    function test_should_transfer_tokens_to_beneficiary_not_caller() public {
        _setStakingContract(address(stakingMock));
        _setVestingStartTime(block.timestamp - 1);

        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();
        
        uint256 initialBalance = artTokenContractUpgradeable.balanceOf(claimer1);
    
        vm.startPrank(address(stakingMock));
        artTokenContractUpgradeable.claimFor(allocatedAmount, merkleProof, claimer1);
        vm.stopPrank();

        assertEq(artTokenContractUpgradeable.balanceOf(claimer1) - initialBalance, allocatedAmount);
        assertEq(artTokenContractUpgradeable.balanceOf(address(stakingMock)), 0);
    }

   

}