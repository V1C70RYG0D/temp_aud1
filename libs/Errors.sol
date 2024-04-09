// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library Errors {
    error InvalidAddress();
    error TotalSupplyZero();
    error AmountZero();
    error NotWhitelisted();
    error CallerNotFactory();
    error PoolNotActive();
    error InvalidAmountOrPrice();
    error InsufficientSecurityTokens();
    error InsufficientBalance();
    error PriceMustBePositive();
    error PoolAlreadyActive();
    error PoolDoesNotExist();
    error NotAdminOrBot();
    error InvalidFeeReceiverAddress();
    error InvalidAddressProvided();
    error AddressAlreadyDelisted();
    error AddressAlreadyListed();
    error WrongFactoryAddress();
    error UnauthorizedAccess();
    error TransferRestricted();

    //EloopCoin
    error ArrayLengthMismatch();

    //MultiSignature
    error TxDoesNotExist();
    error NotMultiSigWallet();
    error InvalidOwnerCount();
    error NotOwner();
    error OwnerAlreadyExists();
    error OwnerDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error NotEnoughConfirmations();
    error TxFailed();
    error InvalidOwnersOrSignatures();
    error TxNotConfirmed();
}