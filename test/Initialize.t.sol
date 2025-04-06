// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.28;

import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";
import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";

contract ArtTokenUpgradeable_Initialize is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_set_correct_contract_name() public view {
        assertEq(artTokenContractUpgradeable.name(), "ArtTokenUpgradeable");
    }

    function test_should_set_correct_contract_symbol() public view {
        assertEq(artTokenContractUpgradeable.symbol(), "ART_UPGRADEABLE");
    }

    function test_should_set_correct_contract_decimals() public view {
        assertEq(artTokenContractUpgradeable.decimals(), 18);
    }

    function test_should_set_correct_owner() public view {
        assertEq(artTokenContractUpgradeable.owner(), deployer);
    }

    function test_should_mint_correct_amount_of_tokens() public view {
        assertEq(artTokenContractUpgradeable.balanceOf(deployer), INITIAL_MINT_AMOUNT * 10 ** artTokenContractUpgradeable.decimals());
    }

}