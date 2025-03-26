// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ContractUnderTest} from "./ContractUnderTest.sol";

contract ArtToken_Getters is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    function test_should_return_claimable_supply() public {
        _setClaimableSupply(100 ether);
        assertEq(artTokenContract.getClaimableSupply(), 100 ether);
    }
}