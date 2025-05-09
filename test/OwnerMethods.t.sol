// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";
import {ArtToken} from "contracts/ArtToken.sol";

contract ArtToken_OwnerMethods is ContractUnderTest {
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

        artTokenContract.mint(user1, mintAmount);
    }

    function test_should_revert_when_minting_when_unauthorized() public {
        vm.startPrank(deployer);
        uint256 mintAmount = 10 ether;
        artTokenContract.mint(user1, mintAmount);
        assertEq(artTokenContract.balanceOf(user1), mintAmount);
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

        artTokenContract.transferOwnership(unauthorizedUser);
    }
}
