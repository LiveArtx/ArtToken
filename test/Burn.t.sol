// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";

contract ArtToken_Initializer is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_reduce_user_supply_when_burning_tokens() public {
        _mintTokens(user1, 10 ether);
        assertEq(artTokenContract.balanceOf(user1), 10 ether);

        vm.startPrank(user1);
        artTokenContract.burn(5 ether);
        assertEq(artTokenContract.balanceOf(user1), 5 ether);
    }

    function test_should_allow_burning_of_tokens_from_approved_user() public {
        _mintTokens(user1, 10 ether);
        assertEq(artTokenContract.balanceOf(user1), 10 ether);

        vm.startPrank(user1);
        artTokenContract.approve(user2, 5 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        artTokenContract.burnFrom(user1, 5 ether);
        assertEq(artTokenContract.balanceOf(user1), 5 ether);
    }

    function test_should_reduce_the_cap_after_burning_tokens() public {
        _mintTokens(user1, 10 ether);

        uint256 initialCapSupply = artTokenContract.cap();

        vm.startPrank(user1);
        artTokenContract.burn(5 ether);

        assertEq(artTokenContract.cap(), initialCapSupply - 5 ether);
    }
}