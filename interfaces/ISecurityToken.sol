// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISecurityToken { 

    // transfer, transferFrom must respect the result of verifyTransfer
    function verifyTransfer(address _from, address _to, uint256 _amount) external view returns (bool success);

    // used to create tokens 
    function mint(address _investor, uint256 _amount) external returns (bool success); 
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns(uint256);
}