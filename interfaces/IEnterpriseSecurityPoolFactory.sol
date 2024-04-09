// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnterpriseSecurityPoolFactory {
    /// @notice Emitted when a new EnterpriseSecurityPool is created.
    /// @param poolId Unique identifier of the newly created pool.
    /// @param poolAddress Address of the newly created pool proxy.
    /// @param securityTokenAddr Address of the security token used in the pool.
    /// @param paymentTokenAddr Address of the payment token used in the pool.
    /// @param name Name of the new pool.
    event NewEnterpriseSecurityPool(
        uint256 indexed poolId,
        address indexed poolAddress,
        address indexed securityTokenAddr,
        address paymentTokenAddr,
        string name
    );
    /// @notice Emitted when an EnterpriseSecurityPool is deleted.
    /// @param id The unique identifier of the deleted pool.
    /// @param pool The address of the pool proxy that was deleted.
    /// @param name The name of the deleted pool.
    event EnterpriseSecurityPoolDeleted(
        uint256 indexed id,
        address indexed pool,
        string name
    );
    /// @notice Emitted when an EnterpriseSecurityPool is activated.
    event EnterpriseSecurityPoolActivated();
    /// @notice Emitted when an EnterpriseSecurityPool is deactivated.
    event EnterpriseSecurityPoolDeactivated();

    function createEnterpriseSecurityPool(
        address _securityTokenAddress,
        address _paymentToken,
        address _utils,
        string memory _name
    ) external returns (address);

    function setImplementation(address newImplementation) external;

    function deleteEnterpriseSecurityPool(uint256 poolId) external;

    function activatePool(uint256 poolId) external;

    function deactivatePool(uint256 poolId) external;
}
