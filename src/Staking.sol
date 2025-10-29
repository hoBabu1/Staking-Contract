//SPDX-License-Identifier:MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    struct User {
        uint256 totalStakedAmount;
        uint256 totalReferal;
        uint256 totalReferalReward;
        uint256 lastUpdatedAt;
        address referrer;
        bool isRegistered;
    }

    error Staking__ZeroAmount();
    error Staking__RefereeNotRegisterdUser();
    event Staking__ReferralRewardPaid();
    event Staking__Staked();

    uint256 public constant ROI_PERCENT = 100; // 1% = 100 basis points
    uint256 public constant REFERRAL_PERCENT = 50; // 0.5% = 50 basis points
    uint256 public constant PERCENT_DIVIDER = 10000;

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

            if (_referrer == address(0)) {
                user.referrer = address(0);
            } else {
                // check wether referre is already registered or not
                User memory referee = userInfo[_referrer];
                if (!referee.isRegistered) {
                    revert Staking__RefereeNotRegisterdUser();
                }
                user.referrer = _referrer;
            }
        }

        // Transfer token to contract
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

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

        user.lastUpdatedAt = block.timestamp;
        user.totalStakedAmount += _amount;

        emit Staking__Staked();
    }
}
