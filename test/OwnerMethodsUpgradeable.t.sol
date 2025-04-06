// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";

contract ArtTokenUpgradeable_OwnerMethods is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_merkle_root_for_unauthorized_address() public {
        vm.startPrank(unauthorizedUser);

           vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setMerkleRoot(bytes32(0));
    }

    function test_should_set_merkle_root_when_authorized() public {
        bytes32 startingRoot = artTokenContractUpgradeable.merkleRoot();

        // sets the root in the function
        _claimerDetails();

        assertNotEq(startingRoot, artTokenContractUpgradeable.merkleRoot());
    }

    function test_should_revert_when_setting_claimable_supply_for_unauthorized_address() public {
         vm.startPrank(unauthorizedUser);

           vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setClaimableSupply(0);
    }

    function test_should_set_claimable_supply_when_authorized() public {
        vm.startPrank(deployer);
        uint256 claimTotal = 10 ether;
        artTokenContractUpgradeable.setClaimableSupply(claimTotal);
        assertEq(artTokenContractUpgradeable.claimableSupply(), claimTotal);
    }

    function test_should_revert_when_setting_vesting_start_time_for_unauthorized_address() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setVestingStartTime(block.timestamp);
    }

    function test_should_perform_successful_mint_when_authorized() public {
        vm.startPrank(unauthorizedUser);
        uint256 mintAmount = 10 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.mint(user1, mintAmount);
    }

    function test_should_revert_when_minting_when_unauthorized() public {
        vm.startPrank(deployer);
        uint256 mintAmount = 10 ether;
        artTokenContractUpgradeable.mint(user1, mintAmount);
        assertEq(artTokenContractUpgradeable.balanceOf(user1), mintAmount);
    }

    function test_should_set_staking_contract_when_authorized() public {
        vm.startPrank(deployer);
        artTokenContractUpgradeable.setStakingContractAddress(address(1));
        assertNotEq(artTokenContractUpgradeable.stakingContractAddress(), address(0));
    }

    function test_should_revert_when_setting_staking_address_unauthorized() public {
        vm.startPrank(unauthorizedUser);

         vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setStakingContractAddress(address(1));
    }

    function test_should_revert_if_setting_vesting_start_time_once_vesting_has_started() public {
        uint256 allocatedAmount = CLAIM_AMOUNT;
        (, bytes32[] memory merkleProof) = _claimerDetails();

        _setVestingStartTime(block.timestamp);

        vm.startPrank(claimer1);
        artTokenContractUpgradeable.claim(allocatedAmount, merkleProof);
        vm.stopPrank();
        
        vm.startPrank(deployer);
        vm.expectRevert("Vesting already started");
        artTokenContractUpgradeable.setVestingStartTime(block.timestamp + 1 days);
        vm.stopPrank();
    }

     function test_should_set_vesting_start_time_when_authorized() public {
        uint256 startTime = block.timestamp + 1 days;
       _setVestingStartTime(startTime);

        assertEq(artTokenContractUpgradeable.vestingStart(), startTime);
    }

    function test_should_revert_if_attempting_to_set_vesting_start_time_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        uint256 startTime = block.timestamp + 1 days;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setVestingStartTime(startTime);
    }

    function test_should_transfer_ownership_if_authorized() public {
        address newOwner = user1;

        vm.startPrank(deployer);
        artTokenContractUpgradeable.transferOwnership(newOwner);
        vm.stopPrank();

        vm.startPrank(user1);
        artTokenContractUpgradeable.acceptOwnership();
        
        assertEq(artTokenContractUpgradeable.owner(), newOwner);
    }

    function test_should_revert_when_attempting_to_transfer_ownership_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.transferOwnership(unauthorizedUser);
    }   
}