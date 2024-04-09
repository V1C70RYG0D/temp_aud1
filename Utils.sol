// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IUtils} from "./interfaces/IUtils.sol";
import {Errors} from "./libs/Errors.sol";

/// @title Utils
/// @dev Implements utility functions including fee management, permissions, and token locks.
contract Utils is AccessControl, IUtils {
    uint256 public eloopFee = 250; // 2.5%
    uint256 public constant FEE_DENOMINATOR = 10_000;
    bytes32 public constant EXTERNAL_BOT = keccak256("EXTERNAL_BOT");
    address public feeReceiver;

    ///Tracks whether a token is locked or not
    mapping(address token => bool lockStatus) public tokenLocks;
    mapping(address token => mapping(address participant => uint8 permission)) public participants;

    uint8 private constant CHECK_SUCCESS = 0;
    uint8 private constant CHECK_ELOCKED = 1;
    uint8 private constant CHECK_ESEND = 2;
    uint8 private constant CHECK_ERECV = 3;

    /// Permission bits
    uint8 public constant PERM_SEND = 0x1;
    uint8 public constant PERM_RECEIVE = 0x2;

    struct UserAccess {
        address[] users; // Array of user addresses
        uint256[] accessIndices; // global
        uint8 permission; // Permission level
    }

    struct AccessGroup {
        address[] poolsStakings; // Array of addresses
        UserAccess[] accesses; 
    }

    /// Modifier to check if the caller is an admin or a bot.
    modifier adminOrBotCheck() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(EXTERNAL_BOT, msg.sender)
        ) revert Errors.NotAdminOrBot();
        _;
    }

    constructor(address feeReceiver_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        if (feeReceiver_ == address(0))
            revert Errors.InvalidFeeReceiverAddress();
        feeReceiver = feeReceiver_;
    }

    /**
     * @dev Function to set the new Eloop fee, only called by admin or bot
     * @param newFee new fee
     * @notice that the fee is divided by the donominator, so 10 000 = 100%, 250 = 2.5%
     */
    function setEloopFee(uint256 newFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eloopFee = newFee;
        emit EloopFeeChanged(newFee);
    }

    /**
     * @dev Function to set the new fee receiver address
     * @param newFeeReceiver Address to be new Fee receiver
     * @notice this function can only be called by the admin or the bot
     */
    function setFeeTo(address newFeeReceiver) external adminOrBotCheck {
        if (newFeeReceiver == address(0))
            revert Errors.InvalidFeeReceiverAddress();
        feeReceiver = newFeeReceiver;
        emit FeeReceiverChanged(newFeeReceiver);
    }

    /**
     * @dev Sets permissions for multiple tokens for multiple participants in one transaction.
     * @param accessGroups nested access groups which contains user addresses, access indices
     * (pointing to specific pools or stakings within the group), and the permissions to be set for these users.
     */
   function setMultiplePermissions(AccessGroup[] calldata accessGroups)
        public adminOrBotCheck
    {
        for (uint256 i = 0; i < accessGroups.length; i++) {
            AccessGroup calldata group = accessGroups[i];
            for (uint256 j = 0; j < group.accesses.length; j++) {
                UserAccess calldata access = group.accesses[j];
                for (uint256 k = 0; k < access.users.length; k++) {
                    for (uint256 l = 0; l < access.accessIndices.length; l++) {
                        uint256 accessIndex = access.accessIndices[l];
                        address poolStaking = group.poolsStakings[accessIndex];
                        address user = access.users[k];
                        uint8 permission = access.permission;
                        participants[poolStaking][user] = permission;
                        emit PermissionSet(poolStaking, user, permission);
                    }
                }
            }
        }
    }
    
    /**
     * @dev Sets or updates permissions for a specific token and participant.
     * @param token Address of the token.
     * @param participant Address of the participant.
     * @param permission Permission flags to be assigned.
     */
    function setPermission(
        address token,
        address participant,
        uint8 permission
    ) public adminOrBotCheck {
        participants[token][participant] = permission;
        emit PermissionSet(token, participant, permission);
    }

    /**
     * @dev Locks or unlocks a token from being transferred.
     * @param token The address of the token to lock or unlock.
     * @param locked A boolean indicating the lock status; true to lock, false to unlock.
     * @notice Locking a token prevents all transfers of that token. This function can only be called by an admin.
     */
    function setLocked(address token, bool locked)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenLocks[token] = locked;
        emit LockSet(token, locked);
    }

    /**
     * @dev Checks if a token transfer is allowed based on the token's lock status and participant permissions.
     * @param token The address of the token being transferred.
     * @param from The address attempting to send tokens.
     * @param to The address attempting to receive tokens.
     * @param amount currently unused.
     * @return A uint8 code representing the result of the transfer check: 0 for success, or an error code for a specific failure reason.
     * @notice This function is used to enforce token locks and participant permissions. It returns a success code if the transfer is allowed, or an error code indicating the reason for disallowance.
     */
    function checkTransfer(
        address token,
        address from,
        address to,
        //solhint-disable-next-line
        uint256 amount
    ) public view returns (uint8) {
        if (tokenLocks[token]) {
            return CHECK_ELOCKED;
        }

        // Check for send permission
        if ((participants[token][from] & PERM_SEND) == 0) {
            return CHECK_ESEND;
        }

        // Check for receive permission
        if ((participants[token][to] & PERM_RECEIVE) == 0) {
            return CHECK_ERECV;
        }

        return CHECK_SUCCESS;
    }
}
