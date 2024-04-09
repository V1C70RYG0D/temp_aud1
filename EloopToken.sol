// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "./libs/Errors.sol";

/// @title Eloop Coin Contract
/// @notice This contract represents the Eloop Coin, an ERC20 token with access control.
/// @dev Extends OpenZeppelin's ERC20 and AccessControl contracts.
contract EloopCoin is ERC20, AccessControl {

    /**
    * @dev Initializes the EloopCoin with an initial supply and grants the deployer the DEFAULT_ADMIN_ROLE.
    * @param initialSupply The amount of tokens to mint initially to the deployer's address.
    */
    constructor(uint256 initialSupply)
        ERC20("Eloop Coin", "EC")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    /**
    * @dev Mints `amount` tokens and assigns them to `to`, increasing the total supply.
    * @notice Only callable by accounts with DEFAULT_ADMIN_ROLE.
    * @param to The address to mint tokens to.
    * @param amount The amount of tokens to mint.
    */
    function mint(address to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(to, amount);
    }

    /**
    * @dev Mints tokens to multiple addresses as specified in `recipients` and `amounts`.
    * @notice Mints a different amount of tokens to each address. Only callable by DEFAULT_ADMIN_ROLE.
    * @param recipients An array of addresses to receive the tokens.
    * @param amounts An array of amounts of tokens to mint to each address in `recipients`.
    */
    function batchMint(address[] memory recipients, uint256[] memory amounts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (recipients.length != amounts.length) {
            revert Errors.ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
    }
}