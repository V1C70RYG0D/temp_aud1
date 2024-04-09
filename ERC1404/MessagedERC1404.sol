// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import {MessagesAndCodes} from "./MessagesAndCodes.sol";
import {SimpleRestrictedToken} from "./SimpleRestrictedToken.sol";

/// @title ERC-1404 implementation with built-in message and code management solution
/// @dev Inherit from this contract to implement your own ERC-1404 token
contract MessagedERC1404 is SimpleRestrictedToken {
    using MessagesAndCodes for MessagesAndCodes.Data;
    MessagesAndCodes.Data internal messagesAndCodes;

    constructor(string memory name, string memory symbol)
        SimpleRestrictedToken(name, symbol)
    {}

    function messageForTransferRestriction(uint8 restrictionCode)
        public
        view
        override
        returns (string memory message)
    {
        message = messagesAndCodes.messages[restrictionCode];
    }
}
