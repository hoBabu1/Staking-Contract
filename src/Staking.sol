//SPDX-License-Identifier:MIT

pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    struct User {
        uint256 totalStakedAmount;
        uint256 totalReferal;
        uint256 totalReferalReward;
        uint256 lastUpdatedAt;
        uint256 lastClaimtime;
        uint256 rewardDebt;
        address referrer;
        bool isRegistered;
    }

    error Staking__ZeroAmount();
    error Staking__RefereeNotRegisterdUser();
    event Staking__ReferralRewardPaid();
    error Staking__ClaimAllowedOnlyOnceIn24Hr(uint256 timeLeft);
    error Staking__IncorrectAmount();
    event Staking__Staked();
    event Staking__ClaimedRoi();
    event Staking__Unstaked(address user, uint256 unstakedAmount);

    uint256 public constant ROI_PERCENT = 100; // 1% = 100 basis points
    uint256 public constant REFERRAL_PERCENT = 50; // 0.5% = 50 basis points
    uint256 public constant PERCENT_DIVIDER = 10000;
    uint256 public claimInterval = 86400;

    uint256 public totalReferralPaid;
    uint256 totalUser;
    mapping(address => User) public userInfo;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount, address _referrer) external {
        User storage user = userInfo[msg.sender];
        if (_amount <= 0) {
            revert Staking__ZeroAmount();
        }

        // Registering for the first time
        if (!user.isRegistered) {
            user.isRegistered = true;
            totalUser++;
            user.lastClaimtime = block.timestamp;

            if (_referrer == address(0)) {
                user.referrer = address(0);
            } else {
                // check wether referre is already registered or not
                User storage referee = userInfo[_referrer];
                if (!referee.isRegistered) {
                    revert Staking__RefereeNotRegisterdUser();
                }
                user.referrer = _referrer;
                user.totalReferal++;
            }
        }

        // Transfer token to contract
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        user.rewardDebt = calculateReward(msg.sender);
        user.lastUpdatedAt = block.timestamp;

        // Transfer reward to referee
        if (user.referrer != address(0)) {
            User storage referrer = userInfo[user.referrer];

            uint256 referralReward = (_amount * REFERRAL_PERCENT) /
                PERCENT_DIVIDER;
            if (referralReward > 0) {
                stakingToken.safeTransfer(user.referrer, referralReward);
                referrer.totalReferal++;
                referrer.totalReferalReward += referralReward;
                totalReferralPaid += referralReward;
                emit Staking__ReferralRewardPaid();
            }
        }

        user.totalStakedAmount += _amount;

        emit Staking__Staked();
    }

    function claimRoi() external {
        User storage user = userInfo[msg.sender];

        if (block.timestamp <= user.lastClaimtime + claimInterval) {
            revert Staking__ClaimAllowedOnlyOnceIn24Hr(
                user.lastClaimtime + claimInterval - block.timestamp
            );
        }
        uint256 rewardAmount = calculateReward(msg.sender);
        user.lastClaimtime = block.timestamp;
        user.rewardDebt = 0;

        stakingToken.safeTransfer(msg.sender, rewardAmount);
        emit Staking__ClaimedRoi();
    }

    function calculateReward(
        address _user
    ) public view returns (uint256 reward) {
        User memory user = userInfo[_user];
        uint256 timePassed = block.timestamp - user.lastUpdatedAt;
        reward =
            (user.totalStakedAmount * ROI_PERCENT * timePassed) /
            (PERCENT_DIVIDER * claimInterval);
        reward += user.rewardDebt;
    }

    function unStake(uint256 _amount) external {
        User storage user = userInfo[msg.sender];

        if (_amount > user.totalStakedAmount) {
            revert Staking__IncorrectAmount();
        }

        user.rewardDebt = calculateReward(msg.sender);
        user.lastUpdatedAt = block.timestamp;
        user.totalStakedAmount -= _amount;

        stakingToken.safeTransfer(msg.sender, _amount);

        emit Staking__Unstaked(msg.sender, _amount);
    }

    function addLiquidity(uint256 _amount) external {
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
