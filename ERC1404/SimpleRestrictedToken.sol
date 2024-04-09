// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import {ERC1404} from "./ERC1404.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error TransferRestricted(uint8 restrictionCode, string message);

/// @title Extendable reference implementation for the ERC-1404 token
/// @dev Inherit from this contract to implement your own ERC-1404 token
contract SimpleRestrictedToken is ERC1404, ERC20 {
    uint8 public constant SUCCESS_CODE = 0;
    string public constant SUCCESS_MESSAGE = "SUCCESS";

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    modifier notRestricted(
        address from,
        address to,
        uint256 value
    ) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        if (restrictionCode != SUCCESS_CODE) {
            revert TransferRestricted(restrictionCode, messageForTransferRestriction(restrictionCode));
        }
        _;
    }

    function detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) public view virtual returns (uint8 restrictionCode) {
        restrictionCode = SUCCESS_CODE;
    }

    function messageForTransferRestriction(uint8 restrictionCode)
        public
        view
        virtual
        returns (string memory message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        }
    }

    function transfer(address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notRestricted(from, to, value) returns (bool success) {
        success = super.transferFrom(from, to, value);
    }
}
