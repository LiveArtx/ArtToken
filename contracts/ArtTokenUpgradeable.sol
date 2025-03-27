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
     * @dev Sets the timestamp for when TGE (Token Generation Event) is enabled.
     * @param _tgeEnabledAt The new TGE enabled timestamp in seconds.
     */
    function setTgeEnabledAt(uint256 _tgeEnabledAt) external onlyOwner {
        require(totalUsersClaimed == 0, "TGE already enabled");
        tgeEnabledAt = _tgeEnabledAt;
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
    function setTgeStartTime(uint256 _startTime) public onlyOwner {
        require(totalUsersClaimed == 0, "TGE already started");
        tgeEnabledAt = _startTime;
    }

    /**
     * @dev Sets the percentage of tokens to be claimed during TGE.
     * @param _percentage The percentage of tokens to claim (1-100).
     */
    function setTgeClaimPercentage(uint256 _percentage) public onlyOwner {
        require(totalUsersClaimed == 0, "TGE already enabled");
        require(_percentage >= 1 && _percentage <= 100, "Value must be between 1 and 100");
        tgeClaimPercentage = _percentage;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CLAIM FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Allows eligible users to claim their allocated tokens. 
     *      Verifies eligibility using Merkle proof and processes the claim based on the TGE.
     * @param allocatedAmount The total number of tokens allocated to the user.
     * @param merkleProof The Merkle proof array for verifying user eligibility.
     */
    function claim(uint256 allocatedAmount, bytes32[] calldata merkleProof) public {
        require(tgeEnabledAt != 0, "TGE not enabled");

        verifyMerkleProof(_msgSender(), allocatedAmount, merkleProof);
        uint256 releaseAmount = calculateReleaseAmount(_msgSender(), allocatedAmount);

        assert((claims[_msgSender()].claimed + releaseAmount) <= allocatedAmount);

        if (claims[_msgSender()].claimed == 0) {
            claims[_msgSender()].amount = allocatedAmount;
            totalUsersClaimed++;
        }

        _processClaim(_msgSender(), releaseAmount);
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
        require(tgeEnabledAt != 0, "TGE not enabled");
        require(stakingContractAddress != address(0), "Staking contract not set");
        require(_msgSender() == stakingContractAddress, "Invalid staking contract address");

        bytes32 leaf = keccak256(abi.encodePacked(receiver, allocatedAmount));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
        require(claims[receiver].claimed == 0, "User already claimed");

        claims[receiver].amount = allocatedAmount;
        totalUsersClaimed++;

        _processClaim(receiver, allocatedAmount);
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

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ INTERNAL FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Processes the user's claim and transfers the tokens.
     * @param claimer The address of the user claiming tokens.
     * @param releaseAmount The number of tokens to release.
     */
    function _processClaim(address claimer, uint256 releaseAmount) private {
        Claim storage userClaim = claims[claimer];
        
        require(releaseAmount <= claimableSupply, "Insufficient claimable supply");
        
        if (isTGEActive()) {
            userClaim.claimedAtTGE = true;
        }

        userClaim.claimed += releaseAmount;
        userClaim.lastClaimed = block.timestamp;
        claimableSupply -= releaseAmount;
        _mint(claimer, releaseAmount);
        
        emit TokensClaimed(claimer, releaseAmount);
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
