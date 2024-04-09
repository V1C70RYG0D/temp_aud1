// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {MessagedERC1404} from "./ERC1404/MessagedERC1404.sol";
import {Errors} from "./libs/Errors.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IUtils} from "./interfaces/IUtils.sol";
import {MessagesAndCodes} from "./ERC1404/MessagesAndCodes.sol";

contract EloopSecurityToken is MessagedERC1404, AccessControl {
    IUtils public utils;

    event UtilsContractUpdated(address indexed newUtils);
    bytes32 public constant MAINTAINER = keccak256("MAINTAINER");

    uint8 constant private CHECK_ELOCKED = 1;
    string constant private ELOCKED_MESSAGE = "Token is locked";
    uint8 constant private CHECK_ESEND = 2;
    string constant private ESEND_MESSAGE = "Sender is not allowed to send the token";
    uint8 constant private CHECK_ERECV = 3;
    string constant private ERECV_MESSAGE = "Receiver is not allowed to receive the token";

    constructor(
        string memory name_,
        string memory symbol_,
        address utils_
    ) MessagedERC1404(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MAINTAINER, msg.sender);
        utils = IUtils(utils_);  

        // Adding predefined messages and codes
        MessagesAndCodes.addMessage(messagesAndCodes, SUCCESS_CODE, SUCCESS_MESSAGE);
        MessagesAndCodes.addMessage(messagesAndCodes, CHECK_ELOCKED, ELOCKED_MESSAGE);
        MessagesAndCodes.addMessage(messagesAndCodes, CHECK_ESEND, ESEND_MESSAGE);
        MessagesAndCodes.addMessage(messagesAndCodes, CHECK_ERECV, ERECV_MESSAGE);
    }
    /**
    * @dev Mints new tokens to the owner's address.
    * @notice Allows the owner to mint a specified amount of tokens.
    * @param supply The amount of tokens to mint.
    * @param to Address of person which will get the tokens.
    */
    function mint(uint256 supply, address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (supply == 0) revert Errors.AmountZero();
        _mint(to, supply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
    * @dev Verifies if a transfer is possible between two addresses with a given amount.
    * @notice Checks transfer restrictions and returns a boolean indicating the possibility of transfer.
    * @param from Address of the sender.
    * @param to Address of the receiver.
    * @param amount The amount of tokens to transfer.
    * @return success Boolean indicating if the transfer is possible.
    */
    function verifyTransfer(
        address from,
        address to,
        uint256 amount
    ) public view returns (bool success) {
        success = detectTransferRestriction(from, to, amount) == 0;
    }

    /**
    * @dev Detects if there are any restrictions on transferring tokens.
    * @notice Checks if both sender and receiver are whitelisted.
    * @param from Address of the sender.
    * @param to Address of the receiver.
    * @param value Amount of tokens to transfer.
    * @return restrictionCode A code indicating the type of restriction, if any (0 for success).
    */
    function detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) public view override returns (uint8 restrictionCode) {
       return utils.checkTransfer(address(this), from, to, value);//@audit does not check if utils contracts is set ( address != 0 )
    }

    /**
     * @dev Updates the address of the utils contrart.
     * @param newUtils The new utility contract address.
     * @notice This function can only be called by the MAINTAINER Role.
     */
    function updateUtilsContract(address newUtils) public onlyRole(MAINTAINER) {
        if (newUtils == address(0)) revert Errors.InvalidAddress();
        utils = IUtils(newUtils);
        emit UtilsContractUpdated(newUtils);
    }
}
