// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ISecurityToken} from "./interfaces/ISecurityToken.sol";
import {IUtils} from "./interfaces/IUtils.sol";
import {IEnterpriseSecurityPool} from "./interfaces/IEnterpriseSecurityPool.sol";
import {Errors} from "./libs/Errors.sol";

/// @title Enterprise Security Pool Contract
/// @notice This contract manages security token transactions, including buying and withdrawing tokens.
/// @dev Utilizes the UUPS Proxy pattern for upgradeable contracts.
contract EnterpriseSecurityPool is
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IEnterpriseSecurityPool
{
    bytes32 public constant ENTERPRISE_ROLE = keccak256("ENTERPRISE_ROLE");
    uint256 public tokenPrice;
    string public name;
    address public espFactory;
    IUtils public utils;
    ISecurityToken public securityToken;
    IERC20 public paymentToken;

    /// @dev Ensures that the caller is the EnterpriseSecurityPool factory.
    modifier checkFactory() {
        if (msg.sender != espFactory) revert Errors.CallerNotFactory();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with necessary addresses and the admin role.
     * @param securityTokenAddress_ Address of the security token.
     * @param paymentToken_ Address of the payment token.
     * @param utils_ Address of the utility contract.
     * @param factory_ Address of the ESP factory.
     * @param admin_ Address of the admin.
     * @param name_ Name of the security pool.
     */
    function initialize(
        address securityTokenAddress_,
        address paymentToken_,
        address utils_,
        address factory_,
        address admin_,
        string memory name_
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        if (
            securityTokenAddress_ == address(0) ||
            paymentToken_ == address(0) ||
            utils_ == address(0)
        ) revert Errors.InvalidAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        utils = IUtils(utils_);
        name = name_;
        espFactory = factory_;
        securityToken = ISecurityToken(securityTokenAddress_);
        paymentToken = IERC20(paymentToken_);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /**
     * @dev Pauses the contract.
     */
    function pause() external checkFactory {
        _pause();
        emit Paused();
    }

    modifier adminOrEnterpriseCheck() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(ENTERPRISE_ROLE, msg.sender)
        ) revert Errors.UnauthorizedAccess();
        _;
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external checkFactory {
        _unpause();
        emit Unpaused();
    }

    /**
     * @dev The pool must be active to execute this function. The function calculates the total price of the
     * security tokens by multiplying the token price with the desired amount, adds a fee, transfers the fee
     * to the fee receiver, and the payment to the pool, then mints the security tokens to the user's address.
     * @notice Allows users to buy security tokens by paying the equivalent amount in payment tokens.
     * @param amount The number of security tokens that the user wants to buy.
     */
    function buy(uint256 amount) public nonReentrant whenNotPaused {
        if (amount == 0 || tokenPrice == 0)
            revert Errors.InvalidAmountOrPrice();
        if (securityToken.balanceOf(address(this)) < amount)
            revert Errors.InsufficientSecurityTokens();

        uint256 transferAmount = tokenPrice * amount;
        uint256 feeAmount = (transferAmount * utils.eloopFee()) /
            utils.FEE_DENOMINATOR();
        paymentToken.transferFrom(msg.sender, utils.feeReceiver(), feeAmount);
        paymentToken.transferFrom(msg.sender, address(this), transferAmount);
        securityToken.transfer(msg.sender, amount);
        emit Buy(msg.sender, amount);
    }

    /**
    * @dev Allows ENTERPRISE_ROLE or DEFAULT_ADMIN_ROLE to deposit tokens into the pool.
    * @param amount The amount of tokens to deposit.
    */
    function deposit(uint256 amount) external adminOrEnterpriseCheck {
        if (amount <= 0) revert Errors.AmountZero();
        securityToken.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Only the owner can set the token price, which must be greater than 0.
     * @notice Sets the price of security tokens in the pool.
     * @param tokenPrice_ The new token price.
     */
    function setTokenPrice(uint256 tokenPrice_)
        external
        adminOrEnterpriseCheck
    {
        if (tokenPrice_ == 0) revert Errors.PriceMustBePositive();
        tokenPrice = tokenPrice_;
    }

    /**
     * @dev Can only be called by the default admin. The function ensures that the amount is non-zero and
     * that the pool's balance of the token is at least equal to the amount to be withdrawn.
     * @notice Withdraws payment tokens from the pool to the caller's address.
     * @param token The token contract address of the payment tokens to be withdrawn.
     * @param amount The amount of payment tokens to withdraw.
     * @param to Wallet to which the tokens will be send.
     */
    function withdraw(
        address token,
        uint256 amount,
        address to
    ) public whenNotPaused adminOrEnterpriseCheck {
        if (amount == 0) revert Errors.InvalidAmountOrPrice();
        if (IERC20(token).balanceOf(address(this)) < amount)
            revert Errors.InsufficientBalance();

        IERC20(token).transfer(to, amount);
        emit Withdrawal(token, amount, to);
    }

    /**
     * @dev This function allows to withdraw funds in an emergency situation.
     * @notice Allows the owner to perform an emergency withdrawal of payment tokens.
     * @param token The address of the payment token to withdraw.
     * @param amount The amount of payment tokens to withdraw.
     * @param to address to send tokens to.
     */
    function emergencyWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).transfer(to, amount);
        emit EmergencyWithdrawal(token, amount, to);
    }
    /**
    * @dev Check the available balance of security tokens in the pool.
    */
    function availableBalance() external view returns (uint256) {
        return securityToken.balanceOf(address(this));
    }

    /**
     * @dev Updates the factory address.
     * @param newFactory Address of the new factory.
     * @notice Can only be called by the current factory or an admin.
     */
    function updateFactoryAddress(address newFactory) external checkFactory {
        if (newFactory == address(0)) revert Errors.InvalidAddress();
        espFactory = newFactory;
        emit FactoryAddressUpdated(newFactory);
    }

    /**
     * @dev Updates the utility contract address.
     * @param newUtils Address of the new utility contract.
     * @notice Can only be called by the current factory or an admin.
     */
    function updateUtilsAddress(address newUtils) external {
        if (
            !(msg.sender == espFactory ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
        ) revert Errors.UnauthorizedAccess();
        if (newUtils == address(0)) revert Errors.InvalidAddress();
        utils = IUtils(newUtils);
        emit UtilsAddressUpdated(newUtils);
    }
}
