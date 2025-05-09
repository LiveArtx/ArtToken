// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";

contract ArtTokenUpgradeable_OwnerMethods is ContractUnderTest {
    function setUp() public virtual override {
        ContractUnderTest.setUp();
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

    function test_should_transfer_ownership_if_authorized() public {
        address newOwner = user1;

        vm.startPrank(deployer);
        artTokenContractUpgradeable.transferOwnership(newOwner);
        vm.stopPrank();

        vm.startPrank(user1);
        artTokenContractUpgradeable.acceptOwnership();

        assertEq(artTokenContractUpgradeable.owner(), newOwner);
    }

    function test_should_revert_when_attempting_to_transfer_ownership_when_unauthorized()
        public
    {
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
