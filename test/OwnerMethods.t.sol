// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";
import {ArtToken} from "contracts/non-upgradable/layer-zero/ArtToken.sol";

contract ArtToken_OwnerMethods is ContractUnderTest {

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

        artTokenContract.setMerkleRoot(bytes32(0));
    }

    function test_should_set_merkle_root_when_authorized() public {
        bytes32 startingRoot = artTokenContract.merkleRoot();

        // sets the root in the function
        _claimerDetails();

        assertNotEq(startingRoot, artTokenContract.merkleRoot());
    }

    function test_should_revert_when_setting_claimable_supply_for_unauthorized_address() public {
         vm.startPrank(unauthorizedUser);

           vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContract.setClaimableSupply(0);
    }

    function test_should_set_claimable_supply_when_authorized() public {
        vm.startPrank(deployer);
        uint256 claimTotal = 10 ether;
        artTokenContract.setClaimableSupply(claimTotal);
        assertEq(artTokenContract.claimableSupply(), claimTotal);
    }

    function test_should_revert_when_setting_tge_enabled_at_for_unauthorized_address() public {
        vm.startPrank(unauthorizedUser);

        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContract.setTgeEnabledAt(block.timestamp);
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

        artTokenContract.mint(user1, mintAmount);
    }

    function test_should_revert_when_minting_when_unauthorized() public {
        vm.startPrank(deployer);
        uint256 mintAmount = 10 ether;
        artTokenContract.mint(user1, mintAmount);
        assertEq(artTokenContract.balanceOf(user1), mintAmount);
    }

    function test_should_set_staking_contract_when_authorized() public {
        vm.startPrank(deployer);
        artTokenContract.setStakingContractAddress(address(1));
        assertNotEq(artTokenContract.stakingContractAddress(), address(0));
    }

    function test_should_revert_when_setting_staking_address_unauthorized() public {
        vm.startPrank(unauthorizedUser);

         vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContract.setStakingContractAddress(address(1));
    }

    

    function test_should_revert_if_setting_tge_enabled_when_tge_already_started() public {
        _performClaimAfterVestingPeriod(claimer1);

        vm.startPrank(deployer);
        uint256 startTime = block.timestamp + 1 days;
        vm.expectRevert("TGE already started");
        artTokenContract.setTgeStartTime(startTime);
    }

     function test_should_set_tge_enabled_when_authorized() public {
        vm.startPrank(deployer);
        uint256 startTime = block.timestamp + 1 days;
        artTokenContract.setTgeStartTime(startTime);

        assertEq(artTokenContract.tgeEnabledAt(), startTime);
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

        artTokenContract.setTgeStartTime(startTime);
    }

    function test_should_transfer_ownership_if_authorized() public {
        address newOwner = user1;

        vm.startPrank(deployer);
        artTokenContract.transferOwnership(newOwner);
        vm.stopPrank();

        vm.startPrank(user1);
        artTokenContract.acceptOwnership();
        
        assertEq(artTokenContract.owner(), newOwner);
    }

    function test_should_revert_when_attempting_to_transfer_ownership_when_unauthorized() public {
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                unauthorizedUser
            )
        );

        artTokenContract.transferOwnership(unauthorizedUser);
    }
    
    
        
}