// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {UUPSProxy} from "./proxy/UUPSProxy.sol";
import {EnterpriseSecurityPool} from "./EnterpriseSecurityPool.sol";
import {Errors} from "./libs/Errors.sol";
import {IEnterpriseSecurityPoolFactory} from "./interfaces/IEnterpriseSecurityPoolFactory.sol";

/// @title Enterprise Security Pool Factory Contract
/// @notice This contract creates and manages instances of EnterpriseSecurityPool.
contract EnterpriseSecurityPoolFactory is
    AccessControl,
    IEnterpriseSecurityPoolFactory
{
    uint256 public nextPoolId;
    mapping(uint256 id => address poolAddr) public poolsById;
    address public implementation;

    /**
     * @dev Sets the initial implementation of the EnterpriseSecurityPool and grants the sender the DEFAULT_ADMIN_ROLE.
     * @param implementation_ Address of the initial implementation contract.
     */
    constructor(address implementation_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        implementation = implementation_;
    }

    /**
     * @dev Creates a new EnterpriseSecurityPool proxy instance.
     * @notice Deploys a new EnterpriseSecurityPool and registers it in the factory.
     * @param securityTokenAddress Address of the security token.
     * @param paymentToken Address of the payment token.
     * @param utils Address of the utility contract.
     * @param name Name of the new EnterpriseSecurityPool.
     * @return Address of the newly created EnterpriseSecurityPool proxy.
     */
    function createEnterpriseSecurityPool(
        address securityTokenAddress,
        address paymentToken,
        address utils,
        string memory name
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            EnterpriseSecurityPool.initialize.selector,
            securityTokenAddress,
            paymentToken,
            utils,
            address(this),
            msg.sender,
            name
        );

        UUPSProxy proxy = new UUPSProxy(
            implementation,
            address(this),
            initData
        );
        uint256 poolId = nextPoolId++;
        poolsById[poolId] = address(proxy);

        emit NewEnterpriseSecurityPool(
            poolId,
            address(proxy),
            securityTokenAddress,
            paymentToken,
            name
        );

        return address(proxy);
    }

    /**
     * @dev Sets a new implementation for the EnterpriseSecurityPool proxy.
     * @notice Updates the implementation contract address.
     * @param newImplementation Address of the new implementation contract.
     */
    function setImplementation(address newImplementation)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        implementation = newImplementation;
    }

    /**
     * @notice Deletes an existing EnterpriseSecurityPool by its ID.
     * @param poolId The unique identifier of the pool to delete.
     * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE. Requires that the pool exists. Emits the EnterpriseSecurityPoolDeleted event upon deletion.
     */
    function deleteEnterpriseSecurityPool(uint256 poolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address poolAddress = poolsById[poolId];
        if (poolAddress == address(0)) revert Errors.PoolDoesNotExist();
        string memory poolName = EnterpriseSecurityPool(poolAddress).name();
        delete poolsById[poolId];
        if (EnterpriseSecurityPool(poolAddress).paused() == false)
            EnterpriseSecurityPool(poolAddress).pause();
        emit EnterpriseSecurityPoolDeleted(poolId, poolAddress, poolName);
    }

    /**
     * @dev Adds an existing EnterpriseSecurityPool to the factory's management.
     * @param poolAddress The address of the existing EnterpriseSecurityPool.
     */
    function addExistingEnterpriseSecurityPool(address poolAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        EnterpriseSecurityPool pool = EnterpriseSecurityPool(poolAddress);
        if (pool.espFactory() != address(this))
            revert Errors.WrongFactoryAddress();
        string memory poolName = pool.name();

        uint256 poolId = nextPoolId++;
        poolsById[poolId] = poolAddress;

        emit NewEnterpriseSecurityPool(
            poolId,
            poolAddress,
            address(pool.securityToken()),
            address(pool.paymentToken()),
            poolName
        );
    }

    /**
     * @dev Activates an EnterpriseSecurityPool by its ID.
     * @notice Unpauses the pool, allowing normal operations.
     * @param poolId The unique identifier of the pool to activate.
     */
    function activatePool(uint256 poolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address poolAddress = poolsById[poolId];
        if (poolAddress == address(0)) revert Errors.PoolDoesNotExist();
        EnterpriseSecurityPool(poolAddress).unpause();
        emit EnterpriseSecurityPoolActivated();
    }

    /**
     * @dev Deactivates an EnterpriseSecurityPool by its ID.
     * @notice Pauses the pool, halting all operations.
     * @param poolId The unique identifier of the pool to deactivate.
     */
    function deactivatePool(uint256 poolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address poolAddress = poolsById[poolId];
        if (poolAddress == address(0)) revert Errors.PoolDoesNotExist();
        EnterpriseSecurityPool(poolAddress).pause();
        emit EnterpriseSecurityPoolDeactivated();
    }

    /**
     * @dev Updates the utils address in all EnterpriseSecurityPool instances.
     * @param newUtils Address of the new utils contract.
     */
    function updateUtilsAddressInAllPools(address newUtils)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newUtils == address(0)) revert Errors.InvalidAddress();
        for (uint256 i = 0; i < nextPoolId; i++) {
            if (poolsById[i] != address(0)) {
                EnterpriseSecurityPool(poolsById[i]).updateUtilsAddress(
                    newUtils
                );
            }
        }
    }

    /**
     * @dev Updates the utils address in a specific EnterpriseSecurityPool instance.
     * @param poolId The unique identifier of the pool to update.
     * @param newUtils Address of the new utils contract.
     */
    function updateUtilsAddressInPool(uint256 poolId, address newUtils)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newUtils == address(0)) revert Errors.InvalidAddress();
        if (poolsById[poolId] == address(0)) revert Errors.PoolDoesNotExist();
        EnterpriseSecurityPool(poolsById[poolId]).updateUtilsAddress(newUtils);
    }

    /**
     * @dev Updates the factory address in all EnterpriseSecurityPool instances.
     * @param newFactory Address of the new factory.
     */
    function updateFactoryAddressInAllPools(address newFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newFactory == address(0)) revert Errors.InvalidAddress();
        for (uint256 i = 0; i < nextPoolId; i++) {
            if (poolsById[i] != address(0)) {
                EnterpriseSecurityPool(poolsById[i]).updateFactoryAddress(
                    newFactory
                );
            }
        }
    }

    /**
     * @dev Updates the factory address in a specific EnterpriseSecurityPool instance.
     * @param poolId The unique identifier of the pool to update.
     * @param newFactory Address of the new factory.
     */
    function updateFactoryAddressInPool(uint256 poolId, address newFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newFactory == address(0)) revert Errors.InvalidAddress();
        if (poolsById[poolId] == address(0)) revert Errors.PoolDoesNotExist();
        EnterpriseSecurityPool(poolsById[poolId]).updateFactoryAddress(
            newFactory
        );
    }
}
