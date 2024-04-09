// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IRewardProtocol {
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 reward);
    event RewardsDistributed(address indexed from, uint256 weiAmount);
    event RewardWithdrawn(address indexed to, uint256 weiAmount);

    function distributeRewards(uint256 _amount) external;

    function withdrawReward() external;

    function withdrawableRewardOf(address _owner) external view returns (uint256);

    function withdrawnRewardOf(address _owner) external view returns (uint256);

    function accumulativeRewardOf(address _owner) external view returns (uint256);

    function rewardOf(address _owner) external view returns (uint256);

    function stake(uint256 _amount) external;
}
