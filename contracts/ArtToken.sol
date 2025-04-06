// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

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

        uint256 claimable = _calculateClaimable(msg.sender, totalAllocation, true);
        require(claimable > 0, "Nothing to claim");

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
        require(stakingContractAddress != address(0), "Staking contract not set");
        require(_msgSender() == stakingContractAddress, "Invalid staking contract address");

        bytes32 leaf = keccak256(abi.encodePacked(receiver, allocatedAmount));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
        require(claimedAmount[receiver] == 0, "User already claimed");

        claimedAmount[receiver] = allocatedAmount;
        initialClaimed[receiver] = true;
        
        totalUsersClaimed++;

        _mint(receiver, allocatedAmount);
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
     * @return The number of decimals for the token.
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the cap of the token. Overridden from ERC20Capped.
     * @return The maximum supply of tokens, excluding burned tokens.
     */
    function cap() public view virtual override(ERC20Capped) returns (uint256) {
        return MAX_SUPPLY - totalBurned;
    }
}
