// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library EventsLib {
    event Staking__UserRegistered(address user);
    event Staking__Staked(address user, uint256 amount, uint256 time);
    event Staking__ClaimedRoi(address user, uint256 rewardAmount, uint256 time);
    event Staking__Unstaked(address user, uint256 unstakedAmount);
    event Staking__ReferralRewardPaid();
}
