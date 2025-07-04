// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OFTUpgradeable} from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";


contract ArtTokenUpgradeableV2 is
    OFTUpgradeable,
    ERC20CappedUpgradeable,
    ERC20PermitUpgradeable,
    Ownable2StepUpgradeable
{
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint8 public constant DECIMALS = 18;

    uint256 public totalBurned;

    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _delegate,
        uint256 initialMintAmount
    ) public initializer {
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
     * @notice Mints a specified amount of tokens to a specified address.
     * @param to The address to mint the tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        address to,
        uint256 amount
    ) public onlyOwner {
        _mint(to, amount);
    }


    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ BURN FUNCTIONS ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    /**
     * @notice Burns a specified amount of tokens from the caller.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
        totalBurned += amount;
    }

    /**
     * @notice Burns a specified amount of tokens from a specified account.
     * @param account The address of the account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        totalBurned += amount;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OVERRIDES ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._update(from, to, value);
    }

    function transferOwnership(
        address newOwner
    )
        public
        virtual
        override(OwnableUpgradeable, Ownable2StepUpgradeable)
        onlyOwner
    {
        Ownable2StepUpgradeable.transferOwnership(newOwner);
    }

    function _transferOwnership(
        address newOwner
    ) internal virtual override(OwnableUpgradeable, Ownable2StepUpgradeable) {
        Ownable2StepUpgradeable._transferOwnership(newOwner);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function cap()
        public
        view
        virtual
        override(ERC20CappedUpgradeable)
        returns (uint256)
    {
        return MAX_SUPPLY - totalBurned;
    }
}
