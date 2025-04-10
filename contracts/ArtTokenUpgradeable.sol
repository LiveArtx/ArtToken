// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "./ArtTokenCore.sol";
import {OFTUpgradeable} from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

/**
 * @title ArtTokenUpgradeable
 * @dev An upgraded token contract with features like minting, burning, claiming, 
 *      and integration with LayerZero for cross-chain functionality. 
 *      Inherits from multiple open-source and upgradeable smart contracts.
 */
contract ArtTokenUpgradeable is ArtTokenCore, OFTUpgradeable, ERC20CappedUpgradeable, ERC20PermitUpgradeable, Ownable2StepUpgradeable {
    
    /**
     * @dev Constructor to initialize the contract with LayerZero endpoint address.
     * @param _lzEndpoint Address of the LayerZero endpoint to be used for cross-chain functionality.
     */
    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    /**
     * @dev Initializer for setting up the token's name, symbol, owner delegate, and initial mint amount.
     * @param _name Name of the token.
     * @param _symbol Symbol for the token.
     * @param _delegate Address of the owner delegate.
     * @param initialMintAmount The initial amount to mint to the delegate.
     */
    function initialize(string memory _name, string memory _symbol, address _delegate, uint256 initialMintAmount)
        public
        initializer
    {
        __OFT_init(_name, _symbol, _delegate);
        __Ownable_init(_delegate);
        __ERC20Capped_init(MAX_SUPPLY);
        __ERC20Permit_init(_name);
        if (initialMintAmount > 0) {
            _mint(_delegate, initialMintAmount * 10 ** decimals());
        }
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OWNER FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Allows the owner to mint tokens to a specified address.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Sets the claimable supply of tokens, ensuring it doesn't exceed the cap.
     * @param amount The new claimable supply amount.
     */
    function setClaimableSupply(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Claimable supply exceeds cap");
        claimableSupply = amount;
        emit SetClaimableSupply(amount);
    }

    /**
     * @dev Sets the Merkle root for claim verification.
     * @param root The Merkle root for claim verification.
     */
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    /**
     * @dev Sets the address of the staking contract for claiming tokens.
     * @param _stakingContract The address of the staking contract.
     */
    function setStakingContractAddress(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Invalid staking contract address");
        stakingContractAddress = _stakingContract;
    }

    /**
     * @dev Sets the start time for the Token Generation Event (TGE).
     * @param _startTime The new start time for TGE.
     */
    function setVestingStartTime(uint256 _startTime) public onlyOwner {
        require(totalUsersClaimed == 0, "Vesting already started");
        vestingStart = _startTime;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CLAIM FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

   /// @notice Allows users to claim their tokens based on vesting and Merkle proof
    /// @param totalAllocation Total allocated amount (as in the Merkle tree)
    /// @param merkleProof Merkle proof validating the user's allocation
    function claim(uint256 totalAllocation, bytes32[] calldata merkleProof) external {
        require(block.timestamp >= vestingStart, "Vesting has not started");

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalAllocation));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid Merkle proof");

        (uint256 claimable, bool hasInitialClaimed) = _calculateClaimable(msg.sender, totalAllocation);
        require(claimable > 0, "Nothing to claim");

        if (!hasInitialClaimed) {
            initialClaimed[msg.sender] = true;
            totalUsersClaimed++;
        }

        claimedAmount[msg.sender] += claimable;

        _mint(msg.sender, claimable);
        emit TokensClaimed(msg.sender, claimable);
    }

    /**
     * @dev Allows the staking contract to claim tokens on behalf of a user.
     * @param allocatedAmount The total number of tokens allocated to the user.
     * @param merkleProof The Merkle proof array for verifying user eligibility.
     * @param receiver The address receiving the claimed tokens.
     */
    function claimFor(uint256 allocatedAmount, bytes32[] calldata merkleProof, address receiver)
        external
    {
        require(block.timestamp >= vestingStart, "Vesting has not started");
        require(_msgSender() == stakingContractAddress, "Invalid staking contract address");

        bytes32 leaf = keccak256(abi.encodePacked(receiver, allocatedAmount));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
        require(claimedAmount[receiver] == 0, "User already claimed");

        claimedAmount[receiver] = allocatedAmount;
        initialClaimed[receiver] = true;
        
        totalUsersClaimed++;

        // Minted to staking contract address as this reduces additional 
        // steps to approve and transfer the tokens within the staking phase
        _mint(stakingContractAddress, allocatedAmount);
        emit TokensClaimed(receiver, allocatedAmount);
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ BURN FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Burns tokens from the caller's account.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        totalBurned += amount;
    }

    /**
     * @dev Burns tokens from a specified account.
     * @param account The address from which to burn tokens.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        totalBurned += amount;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OVERRIDES ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Overrides the ERC20 _update function to add custom behavior for capped token transfers.
     */
    function _update(address from, address to, uint256 value) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._update(from, to, value);
    }

    /**
     * @dev Overrides the transferOwnership function to transfer ownership using Ownable2Step.
     */
    function transferOwnership(address newOwner) public virtual override(OwnableUpgradeable, Ownable2StepUpgradeable) onlyOwner {
        Ownable2StepUpgradeable.transferOwnership(newOwner);
    }

    /**
     * @dev Internal override of transferOwnership to handle the actual ownership transfer.
     */
    function _transferOwnership(address newOwner) internal virtual override(OwnableUpgradeable, Ownable2StepUpgradeable) {
        Ownable2StepUpgradeable._transferOwnership(newOwner);
    }

    /**
     * @dev Returns the decimals used by the token. Overridden from ERC20.
     * @return The number of decimals for the token.
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the cap of the token. Overridden from ERC20Capped.
     * @return The maximum supply of tokens, excluding burned tokens.
     */
    function cap() public view virtual override(ERC20CappedUpgradeable) returns (uint256) {
        return MAX_SUPPLY - totalBurned;
    }
}
