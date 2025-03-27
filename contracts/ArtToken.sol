// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "./ArtTokenCore.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title ArtToken
 * @dev This contract represents the Art Token with capabilities for minting, claiming, and burning tokens,
 *      as well as LayerZero interoperability for cross-chain functionality.
 */
contract ArtToken is ArtTokenCore, OFT, ERC20Capped, ERC20Permit, Ownable2Step {
    /**
     * @dev Constructor to initialize the ArtToken contract
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _lzEndpoint The LayerZero endpoint address
     * @param _delegate The address of the delegate for the owner role
     * @param initialMintAmount The initial mint amount
     */
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTRUCTOR ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        uint256 initialMintAmount
    ) 
      OFT(_name, _symbol, _lzEndpoint, _delegate) 
      ERC20Capped(MAX_SUPPLY) 
      ERC20Permit(_name) 
      Ownable(_delegate) 
    {
        if (initialMintAmount > 0) {
            _mint(_delegate, initialMintAmount * 10 ** decimals());
        }
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OWNER FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Allows the owner to mint tokens to a specified address.
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Sets the claimable supply. Only callable by the owner.
     * @param amount The new claimable supply amount
     */
    function setClaimableSupply(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Claimable supply exceeds cap");
        claimableSupply = amount;
        emit SetClaimableSupply(amount);
    }

    /**
     * @dev Sets the Merkle root. Only callable by the owner.
     * @param root The new Merkle root to be set
     */
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    /**
     * @dev Sets the timestamp for when TGE (Token Generation Event) is enabled.
     * @param _tgeEnabledAt The new TGE enabled timestamp in seconds
     */
    function setTgeEnabledAt(uint256 _tgeEnabledAt) external onlyOwner {
        require(totalUsersClaimed == 0, "TGE already enabled");
        tgeEnabledAt = _tgeEnabledAt;
    }

    /**
     * @dev Sets the address of the staking contract. Only callable by the owner.
     * @param _stakingContract The address of the staking contract
     */
    function setStakingContractAddress(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Invalid staking contract address");
        stakingContractAddress = _stakingContract;
    }

    /**
     * @dev Sets the TGE start time. Only callable by the owner.
     * @param _startTime The new start time for TGE
     */
    function setTgeStartTime(uint256 _startTime) public onlyOwner {
        require(totalUsersClaimed == 0, "TGE already started");
        tgeEnabledAt = _startTime;
    }

    /**
     * @dev Sets the percentage of tokens to be claimed during TGE. Only callable by the owner.
     * @param _percentage The percentage of tokens to claim (1-100)
     */
    function setTgeClaimPercentage(uint256 _percentage) public onlyOwner {
        require(totalUsersClaimed == 0, "TGE already enabled");
        require(_percentage >= 1 && _percentage <= 100, "Value must be between 1 and 100");
        tgeClaimPercentage = _percentage;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CLAIM FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Allows eligible users to claim their allocated tokens. Verifies eligibility using Merkle proof
     *      and processes the claim based on the current TGE or vesting period.
     * @param allocatedAmount The total number of tokens allocated to the user
     * @param merkleProof The Merkle proof array for verifying user eligibility
     */
    function claim(uint256 allocatedAmount, bytes32[] calldata merkleProof) public {
        require(tgeEnabledAt != 0, "TGE not enabled");

        verifyMerkleProof(_msgSender(), allocatedAmount, merkleProof);
        uint256 releaseAmount = calculateReleaseAmount(_msgSender(), allocatedAmount);

        assert((claims[_msgSender()].claimed + releaseAmount) <= allocatedAmount);

        // Update total users claimed if the user has not claimed yet
        if (claims[_msgSender()].claimed == 0) {
            claims[_msgSender()].amount = allocatedAmount;
            totalUsersClaimed++;
        }

        _processClaim(_msgSender(), releaseAmount);
    }

    /**
     * @dev Allows the staking contract to claim tokens on behalf of a user.
     * @param allocatedAmount The total number of tokens allocated to the user
     * @param merkleProof The Merkle proof array for verifying user eligibility
     * @param receiver The address receiving the claimed tokens
     */
    function claimFor(uint256 allocatedAmount, bytes32[] calldata merkleProof, address receiver)
        external
    {
        require(tgeEnabledAt != 0, "TGE not enabled");
        require(stakingContractAddress != address(0), "Staking contract not set");
        require(_msgSender() == stakingContractAddress, "Invalid staking contract address");

        // Create leaf node with total allocation amount using the receiver's address
        bytes32 leaf = keccak256(abi.encodePacked(receiver, allocatedAmount));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
        require(claims[receiver].claimed == 0, "User already claimed");

        claims[receiver].amount = allocatedAmount;
        totalUsersClaimed++;

        _processClaim(receiver, allocatedAmount);
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ BURN FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Burns tokens from the caller's account
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        totalBurned += amount;
    }

    /**
     * @dev Burns tokens from a specified account
     * @param account The address from which to burn tokens
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        totalBurned += amount;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ INTERNAL FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Processes the user's claim and transfers the tokens.
     * @param claimer The address of the user claiming tokens
     * @param releaseAmount The number of tokens to release
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

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OVERRIDES ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @dev Overrides the ERC20 _update function to add custom behavior for capped token transfers.
     */
    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }

    /**
     * @dev Overrides the transferOwnership function to transfer ownership using Ownable2Step.
     */
    function transferOwnership(address newOwner) public virtual override(Ownable, Ownable2Step) onlyOwner {
        Ownable2Step.transferOwnership(newOwner);
    }

    /**
     * @dev Internal override of transferOwnership to handle the actual ownership transfer.
     */
    function _transferOwnership(address newOwner) internal virtual override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }

    /**
     * @dev Returns the decimals used by the token. Overridden from ERC20.
     * @return The number of decimals for the token
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the cap of the token. Overridden from ERC20Capped.
     * @return The maximum supply of tokens, excluding burned tokens
     */
    function cap() public view virtual override(ERC20Capped) returns (uint256) {
        return MAX_SUPPLY - totalBurned;
    }
}
