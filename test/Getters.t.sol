// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.28;

import {ContractUnderTest} from "./base-setup/ContractUnderTest.sol";

contract ArtToken_Getters is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_return_claimable_supply() public {
        _setClaimableSupply(100 ether);
        assertEq(artTokenContract.getClaimableSupply(), 100 ether);
        assertEq(artTokenContractUpgradeable.getClaimableSupply(), 100 ether);
    }
}