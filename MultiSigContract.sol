// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import {Errors} from "./libs/Errors.sol";

/// @title MultiSignatureContract
/// @dev Require multiple signatures for transaction confirmation
contract MultiSignatureContract {
    /// Emitted when a transaction is confirmed by an owner.
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    /// Emitted when an owner revokes their confirmation of a transaction.
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    /// Emitted when a transaction is executed.
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    /// Emited when minimum singatures are disabled.
    event MultiSigPaused();
    /// Emited when minimum signatures are enforced.
    event MultiSigUnpaused();
    /// Emitted when a new transaction is submitted.
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        bytes data
    );
    /// Emited when owners are added or removed from the contract.
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    /// Emitted when the required minimum number of confirmations is changed.
    event MinimumConfirmationChange(uint256 required);

    /// Array of owners which are added to the Multisignature contract.
    address[] public owners;

    mapping(address owner => bool isOwner) public isOwnerMap;
    mapping(uint256 txIndex => mapping(address owner => bool confirmedTx)) public isConfirmedMap;
    uint256 public minSignatures;
    bool public paused;
    Transaction[] public transactions;

    struct Transaction {
        address to;
        bool executed;
        bytes data;
        uint256 confirmations;
        string desc;
    }

    modifier txExists(uint256 txIndex) {
        if(txIndex >= transactions.length) revert Errors.TxDoesNotExist();
        _;
    }

    modifier onlyWallet() {
        if(msg.sender != address(this)) revert Errors.NotMultiSigWallet();
        _;
    }

    modifier validOwnerCount(uint256 ownerCount, uint256 required) {
        if(!(required <= ownerCount && required != 0 && ownerCount != 0)) revert Errors.InvalidOwnerCount();
        _;
    }

    modifier onlyOwner() {
        if(!isOwnerMap[msg.sender]) revert Errors.NotOwner();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if(isOwnerMap[owner]) revert Errors.OwnerAlreadyExists();
        _;
    }

    modifier ownerExists(address owner) {
        if(!isOwnerMap[owner]) revert Errors.OwnerDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 txIndex) {
        if(transactions[txIndex].executed) revert Errors.TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 txIndex) {
        if(isConfirmedMap[txIndex][msg.sender]) revert Errors.TxAlreadyConfirmed();
        _;
    }

    modifier isPaused(uint256 txIndex) {
        if(!paused) {
            Transaction storage transaction = transactions[txIndex];
            if(transaction.confirmations < minSignatures) revert Errors.NotEnoughConfirmations();
        }
        _;
    }

    constructor(address[] memory _owners, uint256 _minSignatures) {
        if(_owners.length == 0 || _minSignatures == 0 || _minSignatures > _owners.length) {
            revert Errors.InvalidOwnersOrSignatures();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if(owner == address(0) || isOwnerMap[owner]) revert Errors.InvalidOwnersOrSignatures();
            isOwnerMap[owner] = true;
            owners.push(owner);
        }
        minSignatures = _minSignatures;
    }

    /**
     * @dev Pauses the contract, allowing execution of transactions without minimum singatures.
     * @notice Can only be called by the contract itself, through a multisignature transaction.
     */
    function pause() external onlyWallet {
        paused = true;
        emit MultiSigPaused();
    }
   /**
     * @dev Unpauses the contract, enforcing minimum signatures.
     * @notice Can only be called by the contract itself, through a multisignature transaction.
     */
    function unpause() external onlyWallet {
        paused = false;
        emit MultiSigUnpaused();
    }

    /**
     * @dev Proposes a new transaction to be sent from the contract.
     * @param toAddress The address the transaction is proposed to.
     * @param data The data of the transaction.
     * @param desc A description of the proposed transaction for recordkeeping.
     * @notice Automatically calls `confirmTransaction` for the proposer, adding the first confirmation.
     */
    function proposeTransaction(
        address toAddress,
        bytes memory data,
        string memory desc
    ) public onlyOwner {
        if(toAddress == address(0)) revert Errors.InvalidAddressProvided();
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: toAddress,
                data: data,
                executed: false,
                confirmations: 0,
                desc: desc
            })
        );
        confirmTransaction(txIndex);
        emit SubmitTransaction(msg.sender, txIndex, toAddress, data);
    }

    /**
     * @dev Adds a confirmation to a proposed transaction by an owner.
     * @param txIndex The index of the transaction in the `transactions` array.
     * @notice Only owners can confirm transactions, and each owner can confirm a transaction exactly once.
     */
    function confirmTransaction(uint256 txIndex)
        public
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
        notConfirmed(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];
        transaction.confirmations += 1;
        isConfirmedMap[txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, txIndex);
    }

    /**
     * @dev Executes a confirmed transaction if the number of confirmations meets the minimum requirement.
     * @param txIndex The index of the transaction in the `transactions` array.
     * @notice Can only be called by an owner. The transaction must not already be executed and must have sufficient confirmations.
     */
    function executeTransaction(uint256 txIndex)
        public
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
        isPaused(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];
        transaction.executed = true;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = transaction.to.call(transaction.data);
        if(!success) revert Errors.TxFailed();
        emit ExecuteTransaction(msg.sender, txIndex);
    }

    /**
     * @dev Revokes a previously given confirmation for a transaction.
     * @param txIndex The index of the transaction in the `transactions` array.
     * @notice Can only be called by an owner who has previously confirmed the transaction.
     */
    function revokeConfirmation(uint256 txIndex)
        public
        onlyOwner
        txExists(txIndex)
        notExecuted(txIndex)
    {
        Transaction storage transaction = transactions[txIndex];
        if(!isConfirmedMap[txIndex][msg.sender]) revert Errors.TxNotConfirmed();
        transaction.confirmations -= 1;
        isConfirmedMap[txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, txIndex);
    }

    /**
     * @dev Returns the details of a specific transaction.
     * @param txIndex The index of the transaction in the `transactions` array.
     * @return toAddress The address the transaction is directed to.
     * @return data The data of the transaction.
     * @return executed A boolean indicating whether the transaction has been executed.
     * @return confirmations The current number of confirmations for the transaction.
     * @return desc A description of the transaction.
     */
    function getTransaction(uint256 txIndex)
        public
        view
        returns (
            address toAddress,
            bytes memory data,
            bool executed,
            uint256 confirmations,
            string memory desc
        )
    {
        Transaction storage transaction = transactions[txIndex];

        return (
            transaction.to,
            transaction.data,
            transaction.executed,
            transaction.confirmations,
            transaction.desc
        );
    }

    /**
     * @dev Changes the minimum number of confirmations required for a transaction to be executed.
     * @param newMinSignatures The new required minimum number of confirmations.
     * @notice Can only be called by the contract itself, typically through a multi-signature transaction.
     */
    function changeMinConfirmation(uint256 newMinSignatures)
        public
        onlyWallet
        validOwnerCount(owners.length, newMinSignatures)
    {
        minSignatures = newMinSignatures;
        emit MinimumConfirmationChange(newMinSignatures);
    }

    /**
     * @dev Adds a new owner to the contract.
     * @param newOwner The address to be added as a new owner.
     * @notice Ensures that the new owner is not already an owner, and adjusts the valid owner count for transactions.
     */
    function addOwner(address newOwner)
        public
        onlyWallet
        ownerDoesNotExist(newOwner)
        validOwnerCount(owners.length + 1, minSignatures)
    {
        isOwnerMap[newOwner] = true;
        owners.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    /**
     * @dev Removes an existing owner from the contract.
     * @param ownerToRemove The address of the owner to be removed.
     * @notice Ensures that the owner exists before removal and adjusts the minimum confirmation requirement if necessary.
     */
    function removeOwner(address ownerToRemove)
        public
        onlyWallet
        ownerExists(ownerToRemove)
    {
        isOwnerMap[ownerToRemove] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (minSignatures > owners.length) changeMinConfirmation(owners.length);
        emit OwnerRemoved(ownerToRemove);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}