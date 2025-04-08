// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtToken.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";

contract ArtToken_Constructor is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_set_correct_contract_name() public view {
        assertEq(artTokenContract.name(), "ArtToken");
    }

    function test_should_set_correct_contract_symbol() public view {
        assertEq(artTokenContract.symbol(), "ART");
    }

    function test_should_set_correct_contract_decimals() public view {
        assertEq(artTokenContract.decimals(), 18);
    }

    function test_should_set_correct_owner() public view {
        assertEq(artTokenContract.owner(), deployer);
    }

    function test_should_mint_correct_amount_of_tokens() public view {
        assertEq(artTokenContract.balanceOf(deployer), INITIAL_MINT_AMOUNT * 10 ** artTokenContract.decimals());
    }

}