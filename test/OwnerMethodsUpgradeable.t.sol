// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import {ArtToken} from "contracts/ArtToken.sol";

contract ArtToken_OwnerMethodsUpgradeable is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_revert_when_setting_merkle_root_for_unauthorized_address() public {
        vm.startPrank(unauthorizedUser);

           vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
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
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
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

    function test_should_revert_when_setting_tge_enabled_at_for_unauthorized_address() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setTgeEnabledAt(block.timestamp);
    }

    function test_should_perform_successful_mint_when_authorized() public {
        vm.startPrank(unauthorizedUser);
        uint256 mintAmount = 10 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
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
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setStakingContractAddress(address(1));
    }

    

    function test_should_revert_if_setting_tge_enabled_when_tge_already_started() public {
        _performClaimAfterVestingPeriod(claimer1);

        vm.startPrank(deployer);
        uint256 startTime = block.timestamp + 1 days;
        vm.expectRevert("TGE already started");
        artTokenContractUpgradeable.setTgeStartTime(startTime);
    }

     function test_should_set_tge_enabled_when_authorized() public {
        vm.startPrank(deployer);
        uint256 startTime = block.timestamp + 1 days;
        artTokenContractUpgradeable.setTgeStartTime(startTime);

        assertEq(artTokenContractUpgradeable.tgeEnabledAt(), startTime);
    }

    function test_should_revert_if_attempting_to_set_tge_enabled_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        uint256 startTime = block.timestamp + 1 days;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setTgeStartTime(startTime);
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
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.transferOwnership(unauthorizedUser);
    }

    function test_should_revert_if_setting_tge_claim_percentage_when_tge_already_started() public {
        _performClaimAfterVestingPeriod(claimer1);

        vm.startPrank(deployer);
        vm.expectRevert("TGE already enabled");
        artTokenContractUpgradeable.setTgeClaimPercentage(25);
    }

     function test_should_set_tge_claim_percentage_when_authorized() public {
        vm.startPrank(deployer);

        uint256 claimPerentage = artTokenContractUpgradeable.tgeClaimPercentage();
        assertNotEq(claimPerentage, 50);
        artTokenContractUpgradeable.setTgeClaimPercentage(50);
        assertEq(artTokenContractUpgradeable.tgeClaimPercentage(), 50);
    }

    function test_should_revert_if_attempting_to_set_tge_claim_percentage_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContractUpgradeable.setTgeClaimPercentage(50);
    }
    
    
        
}