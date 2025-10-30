// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library ErrorsLib {
    error Staking__ZeroAmount();
    error Staking__RefereeNotRegisterdUser();
    event Staking__ReferralRewardPaid();
    error Staking__ClaimAllowedOnlyOnceIn24Hr(uint256 timeLeft);
    error Staking__IncorrectAmount();
}
