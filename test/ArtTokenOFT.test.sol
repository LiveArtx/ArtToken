// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ArtToken.sol";
import "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ArtTokenTest is Test {
    ArtToken artToken;
    address proxy;
    address owner;
    address newOwner;

    // Test helpers for merkle tree
    bytes32[] public merkleProof;
    bytes32 public merkleRoot;
    uint256 public CLAIM_AMOUNT;

    // Add claimer addresses
    address public claimer1;
    address public claimer2;

    // Set up the test environment before running tests
    function setUp() public {
        // Define the owner address
        owner = vm.addr(1);
        claimer1 = vm.addr(2);
        claimer2 = vm.addr(3);
        
        // Deploy the proxy using the contract name
        proxy = Upgrades.deployUUPSProxy(
            "ArtTokenOFT.sol:ArtToken",
            abi.encodeCall(
                ArtToken.initialize,
                (owner, "ART TOKEN", "ART", 1_000_000)
            )
        );
        
        // Attach the ArtToken interface to the deployed proxy
        artToken = ArtToken(proxy);
        // Define a new owner address for upgrade tests
        newOwner = address(1);
        // Emit the owner address for debugging purposes
        emit log_address(owner);

        // Initialize CLAIM_AMOUNT
        CLAIM_AMOUNT = 1000 * 10**artToken.decimals();

        // Create merkle tree with two addresses
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));
        leaves[1] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2)); // claimer2 gets double allocation

        // Sort leaves for consistent merkle tree
        if (uint256(leaves[0]) > uint256(leaves[1])) {
            bytes32 temp = leaves[0];
            leaves[0] = leaves[1];
            leaves[1] = temp;
        }

        // Calculate merkle root
        merkleRoot = keccak256(abi.encodePacked(leaves[0], leaves[1]));

        // Generate proof for claimer1
        merkleProof = new bytes32[](1);
        merkleProof[0] = leaves[1];  // If claimer1's leaf is leaves[0]
        
        // Set merkle root and claimable supply
        vm.prank(owner);
        artToken.setMerkleRoot(merkleRoot);
        
        vm.prank(owner);
        artToken.setClaimableSupply(CLAIM_AMOUNT * 3); // Total supply for both claimers
    }

    // Test the basic ERC20 functionality of the MyToken contract
    function testERC20Functionality() public {
        // Impersonate the owner to call mint function
        vm.prank(owner);
        // Mint tokens to address(2) and assert the balance
        artToken.mint(address(2), 1000);
        assertEq(artToken.balanceOf(address(2)), 1000);
    }

    // Test the upgradeability of the MyToken contract
    function testUpgradeability() public {
        // Get the current implementation address
        address currentImpl = Upgrades.getImplementationAddress(proxy);
        
        // Create options and skip storage check since we're testing with the same contract
        Options memory opts;
        opts.unsafeSkipStorageCheck = true;
        
        // Upgrade the proxy to the new implementation
        // Use the tryCaller parameter to specify the owner address
        Upgrades.upgradeProxy(
            proxy,
            "ArtTokenOFT.sol:ArtToken",
            "",  // Empty bytes since we don't need to call any function during upgrade
            opts,
            owner  // Pass the owner address as the tryCaller
        );
        
        // Verify the implementation was updated
        address newImpl = Upgrades.getImplementationAddress(proxy);
        assertTrue(currentImpl != newImpl);
    }

    function testSetStakingContractAddress() public {
        address newStakingContract = address(0x123);
        
        // Set staking contract address
        vm.prank(owner);
        artToken.setStakingContractAddress(newStakingContract);
        
        // Verify the address was set correctly
        assertEq(artToken.stakingContractAddress(), newStakingContract);
    }

    function testSetStakingContractAddress_RevertZeroAddress() public {
        // Attempt to set zero address should revert
        vm.prank(owner);
        vm.expectRevert("Invalid staking contract address");
        artToken.setStakingContractAddress(address(0));
    }

    function testSetStakingContractAddress_RevertNonOwner() public {
        address newStakingContract = address(0x123);
        
        // Attempt to set address from non-owner should revert
        vm.prank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                address(2)
            )
        );
        artToken.setStakingContractAddress(newStakingContract);
    }

    function testMaxSupply() public {
        uint256 initialSupply = artToken.totalSupply();
        uint256 maxSupply = artToken.cap();
        uint256 remainingSupply = maxSupply - initialSupply;
        
        // Impersonate owner
        vm.prank(owner);
        // Mint the remaining supply (should succeed)
        artToken.mint(address(2), remainingSupply);
        
        // Verify total supply equals cap
        assertEq(artToken.totalSupply(), maxSupply);
        
        // Try to mint 1 more token (should fail)
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20CappedUpgradeable.ERC20ExceededCap.selector,
                maxSupply + 1,
                maxSupply
            )
        );
        artToken.mint(address(2), 1);
    }

    function testMintExceedingMaxSupply() public {
        uint256 maxSupply = artToken.cap();
        uint256 initialSupply = artToken.totalSupply();
        
        // Impersonate owner
        vm.prank(owner);
        
        // Try to mint more than cap in one transaction
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20CappedUpgradeable.ERC20ExceededCap.selector,
                initialSupply + maxSupply,
                maxSupply
            )
        );
        artToken.mint(address(2), maxSupply);
    }

    function testSupplyWithDecimals() public view {
        // Check decimals
        assertEq(artToken.decimals(), 18);
        
        // Initial supply should be 1,000,000 tokens
        uint256 expectedInitialSupply = 1_000_000 * 10**artToken.decimals();
        assertEq(artToken.totalSupply(), expectedInitialSupply);
        
        // Max supply should be 1 billion tokens
        uint256 expectedMaxSupply = 1_000_000_000 * 10**artToken.decimals();
        assertEq(artToken.cap(), expectedMaxSupply);
        
        // Verify remaining supply
        uint256 remainingSupply = artToken.cap() - artToken.totalSupply();
        assertEq(remainingSupply, 999_000_000 * 10**artToken.decimals()); // 999 million tokens remaining
    }

    function testGetClaimableSupply() public {
        uint256 expectedSupply = 1000 * 10**artToken.decimals();
        
        vm.prank(owner);
        artToken.setClaimableSupply(expectedSupply);
        
        assertEq(artToken.getClaimableSupply(), expectedSupply);
    }

    function testSetClaimableSupply() public {
        uint256 newSupply = 1000 * 10**artToken.decimals();
        
        // Should revert when non-owner tries to set claimable supply
        vm.prank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUpgradeable.OwnableUnauthorizedAccount.selector,
                address(2)
            )
        );
        artToken.setClaimableSupply(newSupply);

        // Should succeed when owner sets claimable supply
        vm.prank(owner);
        artToken.setClaimableSupply(newSupply);
        
        // Verify the new claimable supply
        assertEq(artToken.getClaimableSupply(), newSupply);
    }

    function testClaimSuccessClaimer1() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        vm.prank(claimer1);
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, proof);
        
        assertEq(artToken.balanceOf(claimer1), CLAIM_AMOUNT);
        assertEq(artToken.claimedAmount(claimer1), CLAIM_AMOUNT);
        assertEq(artToken.getClaimableSupply(), CLAIM_AMOUNT * 2); // Remaining for claimer2
    }

    function testClaimSuccessClaimer2() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));

        vm.prank(claimer2);
        artToken.claim(CLAIM_AMOUNT * 2, CLAIM_AMOUNT * 2, proof);
        
        assertEq(artToken.balanceOf(claimer2), CLAIM_AMOUNT * 2);
        assertEq(artToken.claimedAmount(claimer2), CLAIM_AMOUNT * 2);
        assertEq(artToken.getClaimableSupply(), CLAIM_AMOUNT); // Remaining for claimer1
    }

    function testPartialClaimClaimer2() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));

        // First claim - half of allocation
        vm.prank(claimer2);
        artToken.claim(CLAIM_AMOUNT * 2, CLAIM_AMOUNT, proof);
        
        assertEq(artToken.balanceOf(claimer2), CLAIM_AMOUNT);
        assertEq(artToken.claimedAmount(claimer2), CLAIM_AMOUNT);
        
        // Second claim - remaining allocation
        vm.prank(claimer2);
        artToken.claim(CLAIM_AMOUNT * 2, CLAIM_AMOUNT, proof);
        
        assertEq(artToken.balanceOf(claimer2), CLAIM_AMOUNT * 2);
        assertEq(artToken.claimedAmount(claimer2), CLAIM_AMOUNT * 2);
    }

    function testClaimFailuresWithProperMerkle() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // Try to claim with wrong address
        vm.prank(address(4));
        vm.expectRevert("Invalid merkle proof");
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, proof);

        // Try to claim more than allocated for claimer1
        vm.prank(claimer1);
        vm.expectRevert("Cannot claim more than allocated");
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT * 2, proof);

        // Successful claim for claimer1
        vm.prank(claimer1);
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, proof);

        // Try to claim again with claimer1
        vm.prank(claimer1);
        vm.expectRevert("Already claimed full allocation");
        artToken.claim(CLAIM_AMOUNT, 1, proof);
    }

    function testClaimWithInsufficientClaimableSupply() public {
        // Set claimable supply to less than claim amount
        vm.prank(owner);
        artToken.setClaimableSupply(CLAIM_AMOUNT - 1);

        // Try to claim full amount
        vm.prank(address(2));
        vm.expectRevert("Insufficient claimable supply");
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, merkleProof);
    }

    function testClaimExceedingRemainingAllocation() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // First claim succeeds
        vm.prank(claimer1);
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT / 2, proof);
        
        // Second claim fails because it would exceed total allocation
        vm.prank(claimer1);
        vm.expectRevert("Claim amount exceeds allocation");
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, proof);
    }

    function testBurnOwnTokens() public {
        // Mint tokens to test address
        vm.prank(owner);
        artToken.mint(address(2), 1000);
        
        // Verify initial balance and supply
        assertEq(artToken.balanceOf(address(2)), 1000);
        uint256 initialSupply = artToken.totalSupply();
        uint256 initialCap = artToken.cap();
        
        // Burn tokens from address(2)
        vm.prank(address(2));
        artToken.burn(500);
        
        // Verify balance, supply, and cap decreased
        assertEq(artToken.balanceOf(address(2)), 500);
        assertEq(artToken.totalSupply(), initialSupply - 500);
        assertEq(artToken.cap(), initialCap - 500);
        assertEq(artToken.totalBurned(), 500);
    }

    function testBurnFromWithAllowance() public {
        // Mint tokens to test address
        vm.prank(owner);
        artToken.mint(address(2), 1000);
        
        // Approve address(3) to spend tokens
        vm.prank(address(2));
        artToken.approve(address(3), 750);
        
        // Verify initial state
        uint256 initialSupply = artToken.totalSupply();
        uint256 initialCap = artToken.cap();
        
        // Burn tokens using burnFrom
        vm.prank(address(3));
        artToken.burnFrom(address(2), 600);
        
        // Verify balance, supply, cap, and allowance
        assertEq(artToken.balanceOf(address(2)), 400);
        assertEq(artToken.totalSupply(), initialSupply - 600);
        assertEq(artToken.cap(), initialCap - 600);
        assertEq(artToken.allowance(address(2), address(3)), 150);
        assertEq(artToken.totalBurned(), 600);
    }

    function testBurnFromWithoutAllowance() public {
        // Mint tokens to test address
        vm.prank(owner);
        artToken.mint(address(2), 1000);
        
        // Try to burn without allowance
        vm.prank(address(3));
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(3), // spender
                0,         // current allowance
                500       // amount required
            )
        );
        artToken.burnFrom(address(2), 500);
    }

    function testBurnMoreThanBalance() public {
        // Mint tokens to test address
        vm.prank(owner);
        artToken.mint(address(2), 1000);
        
        // Try to burn more than balance
        vm.prank(address(2));
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                address(2), // sender
                1000,      // balance
                1500      // amount required
            )
        );
        artToken.burn(1500);
    }

    function testMultipleBurnsUpdateTotalBurned() public {
        // Mint tokens to multiple addresses
        vm.prank(owner);
        artToken.mint(address(2), 1000);
        vm.prank(owner);
        artToken.mint(address(3), 1000);
        
        uint256 initialCap = artToken.cap();
        
        // Perform multiple burns
        vm.prank(address(2));
        artToken.burn(300);
        
        vm.prank(address(3));
        artToken.burn(400);
        
        // Verify cumulative burned amount and cap reduction
        assertEq(artToken.totalBurned(), 700);
        assertEq(artToken.cap(), initialCap - 700);
    }

    function testClaimForSuccess() public {
        // Set up staking contract
        address stakingContract = address(0x123);
        vm.prank(owner);
        artToken.setStakingContractAddress(stakingContract);
        
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // Claim tokens through staking contract
        vm.prank(stakingContract);
        artToken.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);
        
        // Verify tokens went to staking contract
        assertEq(artToken.balanceOf(stakingContract), CLAIM_AMOUNT);
        // Verify claim is tracked against claimer1
        assertEq(artToken.claimedAmount(claimer1), CLAIM_AMOUNT);
        // Verify remaining claimable supply
        assertEq(artToken.getClaimableSupply(), CLAIM_AMOUNT * 2);
    }

    function testClaimForFailures() public {
        // First test: Try to claim before setting staking contract
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        vm.prank(address(4));
        vm.expectRevert("Staking contract not set");
        artToken.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);

        // Set up staking contract
        address stakingContract = address(0x123);
        vm.prank(owner);
        artToken.setStakingContractAddress(stakingContract);

        // Try to claim from non-staking contract
        vm.prank(address(4));
        vm.expectRevert("Invalid staking contract address");
        artToken.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);
    }

    function testClaimForPartialClaims() public {
        address stakingContract = address(0x123);
        vm.prank(owner);
        artToken.setStakingContractAddress(stakingContract);
        
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));

        // First partial claim
        vm.prank(stakingContract);
        artToken.claimFor(CLAIM_AMOUNT * 2, CLAIM_AMOUNT, proof, claimer2);
        
        assertEq(artToken.balanceOf(stakingContract), CLAIM_AMOUNT);
        assertEq(artToken.claimedAmount(claimer2), CLAIM_AMOUNT);
        
        // Second partial claim
        vm.prank(stakingContract);
        artToken.claimFor(CLAIM_AMOUNT * 2, CLAIM_AMOUNT, proof, claimer2);
        
        assertEq(artToken.balanceOf(stakingContract), CLAIM_AMOUNT * 2);
        assertEq(artToken.claimedAmount(claimer2), CLAIM_AMOUNT * 2);
    }

    function testClaimForAndDirectClaimInteraction() public {
        address stakingContract = address(0x123);
        vm.prank(owner);
        artToken.setStakingContractAddress(stakingContract);
        
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // Claim half through staking contract
        vm.prank(stakingContract);
        artToken.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT / 2, proof, claimer1);
        
        // Try to claim more than remaining through direct claim
        vm.prank(claimer1);
        vm.expectRevert("Claim amount exceeds allocation");
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT, proof);
        
        // Claim remaining amount through direct claim
        vm.prank(claimer1);
        artToken.claim(CLAIM_AMOUNT, CLAIM_AMOUNT / 2, proof);
        
        // Verify final state
        assertEq(artToken.balanceOf(stakingContract), CLAIM_AMOUNT / 2);
        assertEq(artToken.balanceOf(claimer1), CLAIM_AMOUNT / 2);
        assertEq(artToken.claimedAmount(claimer1), CLAIM_AMOUNT);
    }

    function testClaimForEmitsEvent() public {
        address stakingContract = address(0x123);
        vm.prank(owner);
        artToken.setStakingContractAddress(stakingContract);
        
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // Expect the TokensClaimedAndStaked event
        vm.expectEmit(true, true, true, true);
        emit ArtToken.TokensClaimedAndStaked(claimer1, CLAIM_AMOUNT);
        
        // Perform claim
        vm.prank(stakingContract);
        artToken.claimFor(CLAIM_AMOUNT, CLAIM_AMOUNT, proof, claimer1);
    }
}