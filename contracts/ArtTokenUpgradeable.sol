// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {OFTUpgradeable} from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {FixedPointMathLib} from "contracts/libraries/FixedPointMathLib.sol";

contract ArtToken is OFTUpgradeable, ERC20CappedUpgradeable, ERC20PermitUpgradeable, Ownable2StepUpgradeable {
    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTANTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    uint8 public constant DECIMALS = 18;
    uint256 public constant TGE_DURATION = 7 days;
    uint256 public constant VESTING_DURATION = 180 days;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ STORAGE ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    mapping(address => uint256) private claimedAmount;
    mapping(address => Claim) private claims;
    bytes32 public merkleRoot;
    uint256 public claimableSupply;
    uint256 public totalBurned;
    uint256 public tgeEnabledAt;
    address public stakingContractAddress;
    uint256 public totalUsersClaimed;

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ STRUCTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    struct Claim {
        uint256 amount;
        uint256 claimed;
        uint256 lastClaimed;
        uint256 dailyRelease;
        bool claimedAtTGE;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ EVENTS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    event TokensClaimed(address indexed user, uint256 amount);
    event TokensClaimedAndStaked(address indexed user, uint256 amount);
    event SetClaimableSupply(uint256 amount);

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CONSTRUCTOR ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ INITIALIZER ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

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

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

       /// @notice Sets the claimable supply - only callable by owner
    /// @param amount The new claimable supply amount
    function setClaimableSupply(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Claimable supply exceeds cap");
        claimableSupply = amount;
        emit SetClaimableSupply(amount);
    }

    /// @notice Sets the merkle root - only callable by owner
    /// @param root The new merkle root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    /// @notice Sets the TGE enabled at - only callable by owner
    /// @param _tgeEnabledAt The new TGE enabled at timestamp in seconds
    function setTgeEnabledAt(uint256 _tgeEnabledAt) external onlyOwner {
        require(totalUsersClaimed == 0, "TGE already enabled");
        tgeEnabledAt = _tgeEnabledAt;
    }

     /// @notice Sets the staking contract address
    /// @param _stakingContract The address of the staking contract
    function setStakingContractAddress(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Invalid staking contract address");
        stakingContractAddress = _stakingContract;
    }


    function setTgeStartTime(uint256 _startTime) public onlyOwner {
        require(totalUsersClaimed == 0, "TGE already started");
        tgeEnabledAt = _startTime;
    }


   
     /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ CLAIM FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
 

    /// @notice Allows eligible users to claim their allocated tokens.
    /// @dev Manages token claims across TGE, vesting, and post-vesting periods.
    /// @dev This function verifies user eligibility via a Merkle proof and processes token claims based on the current period.
    /// @param allocatedAmount The total number of tokens allocated to the user.
    /// @param merkleProof An array of bytes32 hashes proving the user's inclusion in the merkle tree.
    function claim(uint256 allocatedAmount, bytes32[] calldata merkleProof) public {
        _verifyMerkleProof(_msgSender(), allocatedAmount, merkleProof);
        uint256 releaseAmount = calculateReleaseAmount(_msgSender(), allocatedAmount);

        assert((claims[_msgSender()].claimed + releaseAmount) <= allocatedAmount);

         // Update total users claimed if the user has not claimed yet
        if(claims[_msgSender()].claimed == 0) {
            claims[_msgSender()].amount = allocatedAmount;
            totalUsersClaimed++;
        }

        _processClaim(_msgSender(), releaseAmount);
    }

    /// @notice Allows the staking contract to claim tokens for a user
    /// @param allocatedAmount The total amount of tokens allocated
    /// @param merkleProof An array of bytes32 hashes as proof
    /// @param receiver The address to claim tokens for
    function claimFor(uint256 allocatedAmount, bytes32[] calldata merkleProof, address receiver)
        external
    {
        address _stakingContract = stakingContractAddress;
        require(_stakingContract != address(0), "Staking contract not set");
        require(_msgSender() == _stakingContract, "Invalid staking contract address");

        // Create leaf node with total allocation amount using the receiver's address
        bytes32 leaf = keccak256(abi.encodePacked(receiver, allocatedAmount));

        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
        require(claims[receiver].claimed == 0, "User already claim");

        claims[receiver].amount = allocatedAmount;
        totalUsersClaimed++;

        _processClaim(receiver, allocatedAmount); 
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ BURN FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */


    /// @notice Burns tokens from the caller's account
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        totalBurned += amount;
    }

    /// @notice Burns tokens from an account
    /// @param account The address to burn tokens from
    /// @param amount The amount of tokens to burn
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        totalBurned += amount;
    }

     /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ GETTERS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

     /// @notice Returns the current claimable supply
    function getClaimableSupply() public view returns (uint256) {
        return claimableSupply;
    }

     /// @notice Returns the amount of tokens claimed by an address
    /// @param account The address to check
    /// @return uint256 Amount of tokens claimed so far
    function claimDetailsByAccount(address account) external view returns (Claim memory) {
        return claims[account];
    }

    /// @notice Returns the cap of the token
    function cap() public view virtual override(ERC20CappedUpgradeable) returns (uint256) {
        return MAX_SUPPLY - totalBurned;
    }

    function isTGEActive() public view returns (bool) {
        return tgeEnabledAt > 0 && block.timestamp >= tgeEnabledAt && block.timestamp <= tgeEnabledAt + TGE_DURATION;
    }

    function claimingPeriods() public view returns (uint256 tgeStart, uint256 tgeEnd, uint256 vestingEnd) {
        tgeStart = tgeEnabledAt;
        tgeEnd = tgeStart + TGE_DURATION;
        vestingEnd = tgeEnd + VESTING_DURATION;
    }

    function calculateDailyRelease(uint256 _allocatedAmount, uint256 _claimed) public pure returns (uint256) {
        uint256 remaining = _allocatedAmount - _claimed;
        uint256 vestingCliff = 180; // days
        return FixedPointMathLib.divWadDown(remaining, uint256(vestingCliff) * 1e18);
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ HELPER FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */
    function _verifyMerkleProof(address claimer, uint256 allocatedAmount, bytes32[] calldata merkleProof) private view {
        bytes32 leaf = keccak256(abi.encodePacked(claimer, allocatedAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");
    }

    function calculateReleaseAmount(address claimer, uint256 allocatedAmount) private returns (uint256 releaseAmount) {
        require(tgeEnabledAt > 0, "TGE not enabled");
        Claim storage userClaim = claims[claimer];

        // After vesting period, claim all remaining tokens
        (,, uint256 vestingEnd) = claimingPeriods();
        if (block.timestamp >= vestingEnd) {
            return allocatedAmount - userClaim.claimed;
        }

        // During TGE period
        if (isTGEActive()) {
            require(!userClaim.claimedAtTGE, "Already claimed TGE amount");
            uint256 tgeAmount = FixedPointMathLib.mulWadDown(allocatedAmount, 0.25e18);

            // Update claim record
            userClaim.dailyRelease = calculateDailyRelease(allocatedAmount, tgeAmount);
            return tgeAmount;
        }

        // During vesting period
        require(userClaim.lastClaimed + 1 days <= block.timestamp, "Claim only once per day");

        if (userClaim.dailyRelease == 0) {
            uint256 drip = calculateDailyRelease(allocatedAmount, userClaim.claimed);
            userClaim.dailyRelease = drip;
            return drip;
        } else {
            return userClaim.dailyRelease;
        }
    }

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
    function _update(address from, address to, uint256 value) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._update(from, to, value);
    }

    // Override the conflicting functions
    function transferOwnership(address newOwner) public virtual override(OwnableUpgradeable, Ownable2StepUpgradeable) onlyOwner {
        Ownable2StepUpgradeable.transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual override(OwnableUpgradeable, Ownable2StepUpgradeable) {
        Ownable2StepUpgradeable._transferOwnership(newOwner);
    }


}
