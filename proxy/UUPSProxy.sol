// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract UUPSProxy is ERC1967Proxy {
    constructor(
        address _logic,
        address, // This is completely unused by the uups proxy, required to remain compatible with hardhat deploy: https://github.com/wighawag/hardhat-deploy/issues/146
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {}

    /**
     * @dev Get the current implementation contract address
     */
    function implementation() external view returns (address) {
        return _implementation();
    }
}
