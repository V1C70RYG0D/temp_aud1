// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}


/**

Utils: 0x224D7458D4eA7767891Df18715A0D560E600CB25
mSEC: 0x8121b0Ad66b6E23EBA26a07435e70B3AfF44629D 
Pool: 0xCb9fb2762BD3677c61475C8346693b20b120BbC0
Factory: 0x47C728eb3C0b1F9cd144767Af3922591e949F399
mUSDC: 0x07F25BCF9012Fb2582FfaeD4506E17fDf595557c
mSTAKING: 0x4c247736444c2D3cE42cB0Cad6524D1b0F0E0365

*/

/**
Utils: 0x224D7458D4eA7767891Df18715A0D560E600CB25
EloopSecToken: 0x8121b0Ad66b6E23EBA26a07435e70B3AfF44629D
Pool: 0xCb9fb2762BD3677c61475C8346693b20b120BbC0
mUSDC: 0x07F25BCF9012Fb2582FfaeD4506E17fDf595557c
Secuity: 0xdCAE155050eA0b543B19572522B234580ab719B4
Factory: 0x47C728eb3C0b1F9cd144767Af3922591e949F399
mStaking: 0x4c247736444c2D3cE42cB0Cad6524D1b0F0E0365

*/


/**
Nowe Pool: 0x5A8a4F42aE7d6dbFe2f251aDFeF3a9FE8075024F
Factory: 0x47C728eb3C0b1F9cd144767Af3922591e949F399
mSEC: 0xB1f8dfb666f24DD84F4b48413324a28E706BBA3f
mUSDC: 0x07F25BCF9012Fb2582FfaeD4506E17fDf595557c
Utils: 0xFfb2535b244159Dee22803B084E0cBDbe20fAaA0
*/

/**
NEW REDEPLOY:
Fee Receiver: 0xE0E039D10D6CEa83C7DAedb179B0Cfc75e0B0E66
Whitelisting Bot: 0x5A77d6d7077CEb6eed55A0a1a8a319DFABD8fF60
mUSDC Sender: 0x26E628367bf866a3206cb83C1743BCDae2193DFd
Milan Wallet: 0x114B897ea47b9E4812DA224BcD65d4320229A87B
Simon Wallet:

Utils: 0x2d0Aa995Acae3a5FD8632EE28eD187528410bA5a
mUSDC: 0x07F25BCF9012Fb2582FfaeD4506E17fDf595557c
Mock Asset Token: 0x77dF6C0469Adf3ae0202240db271AA70Ebe8f285
Factory: 0x47C728eb3C0b1F9cd144767Af3922591e949F399
Pool: 0x81CD2c5CAc352F8f171e8f185B1D1d802e323bF4
mShares: 0xBB54Fb44c16C6C6Cc17BF105a01c27C9B3b2d5E3
Puhser: 0xC03d80bBEc8BD91b4b0Dae330b6F3F51d0d794f8
whitelister: 5970fdd02d44b8128e45c3f026f2df0700e52dcc2c2d30ce250440ea298e1c82

// 0x8f2631F2bFF02B43e4E23b18D523DFE05861d5d9

// 0x02F09740f6602deb7295162c79435Bbcf3002467
// 0x366d47E4d096a182ad0A28DBa312327B577B9A8d
// 0xCB76f019C40Dd23328D720499703784F093D601e

// 0x93C755681875f615339dD4b13Ce571483E8c88E8
0xB068063E83F62697E01B2Cf8a5C511122870D72D
*/