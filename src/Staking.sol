//SPDX-License-Identifier:MIT

pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {EventsLib} from "./libraries/EventsLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

contract Staking is Ownable, Pausable {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    // ================================================================
    // │                   Struct                                     │
    // ================================================================

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

    // ================================================================
    // │             Constants   and    Storage Variable               │
    // ================================================================

    uint256 public constant ROI_PERCENT = 100; // 1% = 100 basis points
    uint256 public constant REFERRAL_PERCENT = 50; // 0.5% = 50 basis points
    uint256 public constant PERCENT_DIVIDER = 10000;
    uint256 public constant CLAIM_INTYERVAL = 86400;

    uint256 public totalReferralPaid;
    uint256 totalUser;
    mapping(address => User) public userInfo;

    constructor(address _stakingToken, address _owner) Ownable(_owner) {
        stakingToken = IERC20(_stakingToken);
    }

    // ================================================================
    // │                 STAKE                                         │
    // ================================================================

    function stake(uint256 _amount, address _referrer) external whenNotPaused {
        User storage user = userInfo[msg.sender];
        if (_amount <= 0) {
            revert ErrorsLib.Staking__ZeroAmount();
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
                // Assuming one who is registered that person can only refer to others
                User storage referee = userInfo[_referrer];
                if (!referee.isRegistered) {
                    revert ErrorsLib.Staking__RefereeNotRegisterdUser();
                }
                user.referrer = _referrer;
                user.totalReferal++;
            }

            emit EventsLib.Staking__UserRegistered(msg.sender);
        }

        // Transfer token to contract
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Useful when user is re-depositing
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
                emit EventsLib.Staking__ReferralRewardPaid();
            }
        }

        user.totalStakedAmount += _amount;

        emit EventsLib.Staking__Staked(msg.sender, _amount, block.timestamp);
    }

    // ================================================================
    // │                     CALIM ROI                                 │
    // ================================================================
    function claimRoi() external whenNotPaused {
        User storage user = userInfo[msg.sender];

        if (block.timestamp <= user.lastClaimtime + CLAIM_INTYERVAL) {
            revert ErrorsLib.Staking__ClaimAllowedOnlyOnceIn24Hr(
                user.lastClaimtime + CLAIM_INTYERVAL - block.timestamp
            );
        }
        uint256 rewardAmount = calculateReward(msg.sender);
        user.lastUpdatedAt = block.timestamp;
        user.lastClaimtime = block.timestamp;
        user.rewardDebt = 0;

        stakingToken.safeTransfer(msg.sender, rewardAmount);
        emit EventsLib.Staking__ClaimedRoi(
            msg.sender,
            rewardAmount,
            block.timestamp
        );
    }

    // ================================================================
    // │                    Reward Calculation                         │
    // ================================================================

    function calculateReward(
        address _user
    ) public view returns (uint256 reward) {
        User memory user = userInfo[_user];
        uint256 timePassed = block.timestamp - user.lastUpdatedAt;
        reward =
            (user.totalStakedAmount * ROI_PERCENT * timePassed) /
            (PERCENT_DIVIDER * CLAIM_INTYERVAL);
        reward += user.rewardDebt;
    }

    // ================================================================
    // │                 UNSTAKE                                        │
    // ================================================================

    function unStake(uint256 _amount) external whenNotPaused {
        User storage user = userInfo[msg.sender];

        if (_amount > user.totalStakedAmount) {
            revert ErrorsLib.Staking__IncorrectAmount();
        }

        user.rewardDebt = calculateReward(msg.sender);
        user.lastUpdatedAt = block.timestamp;
        user.totalStakedAmount -= _amount;

        stakingToken.safeTransfer(msg.sender, _amount);

        emit EventsLib.Staking__Unstaked(msg.sender, _amount);
    }

    // ================================================================
    // │                   onlyOwner                                   │
    // ================================================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ================================================================
    // │                   Getters                                      │
    // ================================================================

    function getTotalUser() external view returns (uint256) {
        return totalUser;
    }

    function getUserInfo(
        address _user
    ) external view returns (User memory user) {
        user = userInfo[_user];
    }

    function getTotalRefferalPaid() external view returns (uint256) {
        return totalReferralPaid;
    }
}
