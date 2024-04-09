// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20Token} from "./MockToken.sol";

contract MockRamping {
    IERC20 public paymentToken;
    MockERC20Token public receiveToken;

    constructor(address _paymentToken){
        paymentToken = IERC20(_paymentToken);
        receiveToken = new MockERC20Token("Mock USDC","mUSDC",1e18);
    }

    function exchange(uint256 _amount) public {
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        receiveToken.mint(msg.sender,_amount);
    }
}
