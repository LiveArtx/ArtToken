// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {ArtToken} from "contracts/non-upgradable/layer-zero/ArtToken.sol";
import {ContractUnderTest} from "./ContractUnderTest.sol";

import "forge-std/Test.sol";

contract ArtTokenTest_OFT_NonUpgradable is ContractUnderTest {

    function setUp() public virtual override{
        ContractUnderTest.setUp();
    }

    // Test the basic ERC20 functionality of the MyToken contract
    // function testERC20Functionality() public {
    //     // Impersonate the owner to call mint function
    //     vm.prank(owner);
    //     // Mint tokens to address(2) and assert the balance
    //     oft.mint(address(2), 1000);
    //     assertEq(oft.balanceOf(address(2)), 1000);
    // }

    // function testSetStakingContractAddress() public {
    //     address newStakingContract = address(0x123);

    //     // Set staking contract address
    //     vm.prank(owner);
    //     oft.setStakingContractAddress(newStakingContract);

    //     // Verify the address was set correctly
    //     assertEq(oft.stakingContractAddress(), newStakingContract);
    // }

    // function testSetStakingContractAddress_RevertZeroAddress() public {
    //     // Attempt to set zero address should revert
    //     vm.prank(owner);
    //     vm.expectRevert("Invalid staking contract address");
    //     oft.setStakingContractAddress(address(0));
    // }

    // function testSetStakingContractAddress_RevertNonOwner() public {
    //     address newStakingContract = address(0x123);

    //     // Attempt to set address from non-owner should revert
    //     vm.prank(address(2));
    //     vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(2)));
    //     oft.setStakingContractAddress(newStakingContract);
    // }

    // function testMaxSupply() public {
    //     uint256 initialSupply = oft.totalSupply();
    //     uint256 maxSupply = oft.cap();
    //     uint256 remainingSupply = maxSupply - initialSupply;

    //     // Impersonate owner
    //     vm.prank(owner);
    //     // Mint the remaining supply (should succeed)
    //     oft.mint(address(2), remainingSupply);

    //     // Verify total supply equals cap
    //     assertEq(oft.totalSupply(), maxSupply);

    //     // Try to mint 1 more token (should fail)
    //     vm.prank(owner);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, maxSupply + 1, maxSupply)
    //     );
    //     oft.mint(address(2), 1);
    // }

    // function testMintExceedingMaxSupply() public {
    //     uint256 maxSupply = oft.cap();
    //     uint256 initialSupply = oft.totalSupply();

    //     // Impersonate owner
    //     vm.prank(owner);

    //     // Try to mint more than cap in one transaction
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             ERC20Capped.ERC20ExceededCap.selector, initialSupply + maxSupply, maxSupply
    //         )
    //     );
    //     oft.mint(address(2), maxSupply);
    // }

    // function testSupplyWithDecimals() public view {
    //     // Check decimals
    //     assertEq(oft.decimals(), 18);

    //     // Initial supply should be 1,000,000 tokens
    //     uint256 expectedInitialSupply = 1_000_000 * 10 ** oft.decimals();
    //     assertEq(oft.totalSupply(), expectedInitialSupply);

    //     // Max supply should be 1 billion tokens
    //     uint256 expectedMaxSupply = 1_000_000_000 * 10 ** oft.decimals();
    //     assertEq(oft.cap(), expectedMaxSupply);

    //     // Verify remaining supply
    //     uint256 remainingSupply = oft.cap() - oft.totalSupply();
    //     assertEq(remainingSupply, 999_000_000 * 10 ** oft.decimals()); // 999 million tokens remaining
    // }

    // function testGetClaimableSupply() public {
    //     uint256 expectedSupply = 1000 * 10 ** oft.decimals();

    //     vm.prank(owner);
    //     oft.setClaimableSupply(expectedSupply);

    //     assertEq(oft.getClaimableSupply(), expectedSupply);
    // }

    // function testSetClaimableSupply() public {
    //     uint256 newSupply = 1000 * 10 ** oft.decimals();

    //     // Should revert when non-owner tries to set claimable supply
    //     vm.prank(address(2));
    //     vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(2)));
    //     oft.setClaimableSupply(newSupply);

    //     // Should succeed when owner sets claimable supply
    //     vm.prank(owner);
    //     oft.setClaimableSupply(newSupply);

    //     // Verify the new claimable supply
    //     assertEq(oft.getClaimableSupply(), newSupply);
    // }

    // function testClaimSuccessClaimer1() public {
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     vm.prank(claimer1);
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     assertEq(oft.balanceOf(claimer1), CLAIM_AMOUNT);
    //     assertEq(oft.claimedAmount(claimer1), CLAIM_AMOUNT);
    //     assertEq(oft.getClaimableSupply(), CLAIM_AMOUNT * 2); // Remaining for claimer2
    // }

    // function testClaimSuccessClaimer2() public {
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));

    //     vm.prank(claimer2);
    //     oft.claim(CLAIM_AMOUNT * 2, proof);

    //     assertEq(oft.balanceOf(claimer2), CLAIM_AMOUNT * 2);
    //     assertEq(oft.claimedAmount(claimer2), CLAIM_AMOUNT * 2);
    //     assertEq(oft.getClaimableSupply(), CLAIM_AMOUNT); // Remaining for claimer1
    // }

    // function testPartialClaimClaimer2() public {
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));

    //     // First claim - half of allocation
    //     vm.prank(claimer2);
    //     oft.claim(CLAIM_AMOUNT * 2, proof);

    //     assertEq(oft.balanceOf(claimer2), CLAIM_AMOUNT);
    //     assertEq(oft.claimedAmount(claimer2), CLAIM_AMOUNT);

    //     // Second claim - remaining allocation
    //     vm.prank(claimer2);
    //     oft.claim(CLAIM_AMOUNT * 2, proof);

    //     assertEq(oft.balanceOf(claimer2), CLAIM_AMOUNT * 2);
    //     assertEq(oft.claimedAmount(claimer2), CLAIM_AMOUNT * 2);
    // }

    // function testClaimFailuresWithProperMerkle() public {
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     // Try to claim with wrong address
    //     vm.prank(address(4));
    //     vm.expectRevert("Invalid merkle proof");
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Try to claim more than allocated for claimer1
    //     vm.prank(claimer1);
    //     vm.expectRevert("Cannot claim more than allocated");
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Successful claim for claimer1
    //     vm.prank(claimer1);
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Try to claim again with claimer1
    //     vm.prank(claimer1);
    //     vm.expectRevert("Already claimed full allocation");
    //     oft.claim(CLAIM_AMOUNT, proof);
    // }

    // function testClaimWithInsufficientClaimableSupply() public {
    //     // Set claimable supply to less than claim amount
    //     vm.prank(owner);
    //     oft.setClaimableSupply(CLAIM_AMOUNT - 1);

    //     // Try to claim full amount
    //     vm.prank(address(2));
    //     vm.expectRevert("Insufficient claimable supply");
    //     oft.claim(CLAIM_AMOUNT, merkleProof);
    // }

    // function testClaimExceedingRemainingAllocation() public {
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     // First claim succeeds
    //     vm.prank(claimer1);
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Second claim fails because it would exceed total allocation
    //     vm.prank(claimer1);
    //     vm.expectRevert("Claim amount exceeds allocation");
    //     oft.claim(CLAIM_AMOUNT, proof);
    // }

    // function testBurnOwnTokens() public {
    //     // Mint tokens to test address
    //     vm.prank(owner);
    //     oft.mint(address(2), 1000);

    //     // Verify initial balance and supply
    //     assertEq(oft.balanceOf(address(2)), 1000);
    //     uint256 initialSupply = oft.totalSupply();
    //     uint256 initialCap = oft.cap();

    //     // Burn tokens from address(2)
    //     vm.prank(address(2));
    //     oft.burn(500);

    //     // Verify balance, supply, and cap decreased
    //     assertEq(oft.balanceOf(address(2)), 500);
    //     assertEq(oft.totalSupply(), initialSupply - 500);
    //     assertEq(oft.cap(), initialCap - 500);
    //     assertEq(oft.totalBurned(), 500);
    // }

    // function testBurnFromWithAllowance() public {
    //     // Mint tokens to test address
    //     vm.prank(owner);
    //     oft.mint(address(2), 1000);

    //     // Approve address(3) to spend tokens
    //     vm.prank(address(2));
    //     oft.approve(address(3), 750);

    //     // Verify initial state
    //     uint256 initialSupply = oft.totalSupply();
    //     uint256 initialCap = oft.cap();

    //     // Burn tokens using burnFrom
    //     vm.prank(address(3));
    //     oft.burnFrom(address(2), 600);

    //     // Verify balance, supply, cap, and allowance
    //     assertEq(oft.balanceOf(address(2)), 400);
    //     assertEq(oft.totalSupply(), initialSupply - 600);
    //     assertEq(oft.cap(), initialCap - 600);
    //     assertEq(oft.allowance(address(2), address(3)), 150);
    //     assertEq(oft.totalBurned(), 600);
    // }

    // function testBurnFromWithoutAllowance() public {
    //     // Mint tokens to test address
    //     vm.prank(owner);
    //     oft.mint(address(2), 1000);

    //     // Try to burn without allowance
    //     vm.prank(address(3));
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IERC20Errors.ERC20InsufficientAllowance.selector,
    //             address(3), // spender
    //             0, // current allowance
    //             500 // amount required
    //         )
    //     );
    //     oft.burnFrom(address(2), 500);
    // }

    // function testBurnMoreThanBalance() public {
    //     // Mint tokens to test address
    //     vm.prank(owner);
    //     oft.mint(address(2), 1000);

    //     // Try to burn more than balance
    //     vm.prank(address(2));
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             IERC20Errors.ERC20InsufficientBalance.selector,
    //             address(2), // sender
    //             1000, // balance
    //             1500 // amount required
    //         )
    //     );
    //     oft.burn(1500);
    // }

    // function testMultipleBurnsUpdateTotalBurned() public {
    //     // Mint tokens to multiple addresses
    //     vm.prank(owner);
    //     oft.mint(address(2), 1000);
    //     vm.prank(owner);
    //     oft.mint(address(3), 1000);

    //     uint256 initialCap = oft.cap();

    //     // Perform multiple burns
    //     vm.prank(address(2));
    //     oft.burn(300);

    //     vm.prank(address(3));
    //     oft.burn(400);

    //     // Verify cumulative burned amount and cap reduction
    //     assertEq(oft.totalBurned(), 700);
    //     assertEq(oft.cap(), initialCap - 700);
    // }

    // function testClaimForSuccess() public {
    //     // Set up staking contract
    //     address stakingContract = address(0x123);
    //     vm.prank(owner);
    //     oft.setStakingContractAddress(stakingContract);

    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     // Claim tokens through staking contract
    //     vm.prank(stakingContract);
    //     oft.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);

    //     // Verify tokens went to staking contract
    //     assertEq(oft.balanceOf(stakingContract), CLAIM_AMOUNT);
    //     // Verify claim is tracked against claimer1
    //     assertEq(oft.claimedAmount(claimer1), CLAIM_AMOUNT);
    //     // Verify remaining claimable supply
    //     assertEq(oft.getClaimableSupply(), CLAIM_AMOUNT * 2);
    // }

    // function testClaimForFailures() public {
    //     // First test: Try to claim before setting staking contract
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     vm.prank(address(4));
    //     vm.expectRevert("Staking contract not set");
    //     oft.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);

    //     // Set up staking contract
    //     address stakingContract = address(0x123);
    //     vm.prank(owner);
    //     oft.setStakingContractAddress(stakingContract);

    //     // Try to claim from non-staking contract
    //     vm.prank(address(4));
    //     vm.expectRevert("Invalid staking contract address");
    //     oft.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);
    // }

   
    // function testClaimForAndDirectClaimInteraction() public {
    //     address stakingContract = address(0x123);
    //     vm.prank(owner);
    //     oft.setStakingContractAddress(stakingContract);

    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     // Claim half through staking contract
    //     vm.prank(stakingContract);
    //     oft.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT / 2, proof, claimer1);

    //     // Try to claim more than remaining through direct claim
    //     vm.prank(claimer1);
    //     vm.expectRevert("Claim amount exceeds allocation");
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Claim remaining amount through direct claim
    //     vm.prank(claimer1);
    //     oft.claim(CLAIM_AMOUNT, proof);

    //     // Verify final state
    //     assertEq(oft.balanceOf(stakingContract), CLAIM_AMOUNT / 2);
    //     assertEq(oft.balanceOf(claimer1), CLAIM_AMOUNT / 2);
    //     assertEq(oft.claimedAmount(claimer1), CLAIM_AMOUNT);
    // }

    // function testClaimForEmitsEvent() public {
    //     address stakingContract = address(0x123);
    //     vm.prank(owner);
    //     oft.setStakingContractAddress(stakingContract);

    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

    //     // Expect the TokensClaimedAndStaked event
    //     vm.expectEmit(true, true, true, true);
    //     emit ArtToken.TokensClaimedAndStaked(claimer1, CLAIM_AMOUNT);

    //     // Perform claim
    //     vm.prank(stakingContract);
    //     oft.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);
    // }
}