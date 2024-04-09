// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUtils {
    // Event declarations to reflect the operations in the Utils contract
    event EloopFeeChanged(uint256 newFee); 
    event FeeReceiverChanged(address newFeeReceiver); 
    event LockSet(address indexed token, bool locked); 
    event PermissionSet(address indexed token, address indexed participant, uint8 permission);

    // Interface methods for accessing constant values
    //solhint-disable-next-line
    function FEE_DENOMINATOR() external view returns (uint256);
    function feeReceiver() external view returns (address);
    function eloopFee() external view returns(uint256);

    // Interface methods for contract actions
    function setEloopFee(uint256 _newFee) external;
    function setFeeTo(address _newFeeReceiver) external;
    function setPermission(address _token, address _participant, uint8 _permission) external;
    function setLocked(address _token, bool _locked) external; 

    // Method for checking transfer permissions and conditions
    function checkTransfer(address _token, address _from, address _to, uint256 _amount) external view returns (uint8);
}
