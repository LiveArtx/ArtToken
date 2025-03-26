// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtTokenUpgradeable.sol";
import {ContractUnderTestUpgradable} from "./base-setup/ContractUnderTestUpgradeable.sol";

contract ArtToken_Initialize is ContractUnderTestUpgradable {

    function setUp() public virtual override{
        ContractUnderTestUpgradable.setUp();
    }

    function test_should_set_correct_contract_name() public view {
        assertEq(artTokenContract.name(), "ArtTokenUpgradeable");
    }

    function test_should_set_correct_contract_symbol() public view {
        assertEq(artTokenContract.symbol(), "ART_UPGRADEABLE");
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