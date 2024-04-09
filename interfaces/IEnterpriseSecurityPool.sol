// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IEnterpriseSecurityPool {
    /// @notice Emitted when tokens are bought.
    /// @param user Address of the buyer.
    /// @param amount Amount of tokens bought.
    event Buy(address indexed user, uint256 amount);

    /// @notice Emitted when tokens are withdrawn by enterprise.
    /// @param token Address of the token
    /// @param amount Amount of withdrawn tokens.
    /// @param receiver Address of the receiver.
    event Withdrawal(
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    /// @notice Emitted when tokens are emergency withdraw.
    /// @param token Address of the token
    /// @param amount Amount of withdrawn tokens.
    /// @param receiver Address of the receiver.
    event EmergencyWithdrawal(
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    /// @notice Emitted when security tokens are deposited to pool.
     event Deposit(address indexed from, uint256 amount);

    event FactoryAddressUpdated(address newFactory);
    event UtilsAddressUpdated(address newUtils);
    
    event Paused();
    event Unpaused();

}