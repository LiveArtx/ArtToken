// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


contract ArtToken is OFT, ERC20Capped, ERC20Permit, Ownable2Step {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint8 public constant DECIMALS = 18;
    
    uint256 public totalBurned;

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
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        totalBurned += amount;
    }

    /**
     * @notice Burns a specified amount of tokens from a specified account.
     * @param account The address of the account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        totalBurned += amount;
    }

    /* ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ OVERRIDES ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ */

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }

    function transferOwnership(
        address newOwner
    )
        public
        virtual
        override(Ownable, Ownable2Step)
        onlyOwner
    {
        Ownable2Step.transferOwnership(newOwner);
    }

    function _transferOwnership(
        address newOwner
    ) internal virtual override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function cap()
        public
        view
        virtual
        override(ERC20Capped)
        returns (uint256)
    {
        return MAX_SUPPLY - totalBurned;
    }
} 
