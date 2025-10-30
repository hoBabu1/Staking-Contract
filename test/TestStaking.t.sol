//SPDX-License-Identifier : MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {MockToken} from "./MockToken.sol";

contract TestStaking is Test {
    Staking staking;
    MockToken mockToken;

    address owner = makeAddr("Owner");
    address user = makeAddr("User");
    address Bob = makeAddr("Bob");

    uint256 initalAmount = 100e18;

    function setUp() external {
        vm.startPrank(owner);
        mockToken = new MockToken();
        staking = new Staking(address(mockToken),msg.sender);
        mockToken.transfer(user, initalAmount);
        vm.stopPrank();
    }

    /**
     *  Assuming that  pre - registration is required for referring
     */

    function test_stake_Claim_Unstake() public {
        assertEq(mockToken.balanceOf(address(staking)), 0);
        assertEq(mockToken.balanceOf(user), initalAmount);

        vm.startPrank(user);
        mockToken.approve(address(staking), initalAmount);
        staking.stake(initalAmount, address(0));
        vm.stopPrank();

        assertEq(mockToken.balanceOf(address(staking)), initalAmount);
        assertEq(mockToken.balanceOf(user), 0);

        (
            uint256 totalStakedAmount,
            uint256 totalReferal,
            uint256 totalReferalReward,
            uint256 lastUpdatedAt,
            uint256 lastClaimtime,
            uint256 rewardDebt,
            address referrer,
            bool isRegistered
        ) = staking.userInfo(user);

        assertEq(totalStakedAmount, initalAmount);
        assertEq(totalReferal, 0);
        assertEq(totalReferalReward, 0);
        assertEq(lastUpdatedAt, block.timestamp);
        assertEq(lastClaimtime, block.timestamp);
        assertEq(rewardDebt, 0);
        assertEq(referrer, address(0));
        assertEq(isRegistered, true);

        vm.warp(block.timestamp + 86400);
        /**
         * Staking again and checking correct updation of reward and a vairable
         */

        vm.startPrank(owner);
        mockToken.transfer(user, initalAmount);
        vm.stopPrank();

        vm.startPrank(user);
        mockToken.approve(address(staking), initalAmount);
        staking.stake(initalAmount, address(0));
        vm.stopPrank();

        (
            uint256 _totalStakedAmount,
            ,
            ,
            uint256 _lastUpdatedAt,
            uint256 _lastClaimtime,
            uint256 _rewardDebt,
            ,

        ) = staking.userInfo(user);

        assertEq(_totalStakedAmount, initalAmount + initalAmount);
        assertEq(_lastUpdatedAt, block.timestamp);
        assertEq(_lastClaimtime, block.timestamp - 86400);
        assertEq(_rewardDebt, 1e18);

        // User 2 Will stake with a refferal of User1

        vm.startPrank(owner);
        mockToken.transfer(Bob, initalAmount);
        vm.stopPrank();

        vm.startPrank(Bob);
        mockToken.approve(address(staking), initalAmount);
        staking.stake(initalAmount, user);
        vm.stopPrank();

        (
            ,
            uint256 _totalReferal,
            uint256 _totalReferalReward,
            ,
            ,
            ,
            ,

        ) = staking.userInfo(user);

        /**
         * 0.5% of 100e18 = 5e17
         */
        assertEq(_totalReferal, 1);
        assertEq(_totalReferalReward, 5e17);
        assertEq(mockToken.balanceOf(user), 5e17);

        // Claim

        vm.warp(block.timestamp + 86400);

        /**
         * User is having 2 deposit 100e18 each
         * 1st deposit ROI - 2e18
         * 2nd deposit ROI -1e18
         * Total reeward debt will be 3e18
         */

        uint256 rewardDebtOfUser = staking.calculateReward(user);
        assertEq(rewardDebtOfUser, 3e18);

        vm.startPrank(user);
        staking.claimRoi();
        vm.stopPrank();
        assertEq(mockToken.balanceOf(user), 3e18 + 5e17);

        (, , , , uint256 __lastClaimtime, uint256 __rewardDebt, , ) = staking
            .userInfo(user);

        assertEq(__lastClaimtime, block.timestamp);
        assertEq(__rewardDebt, 0);

        // Unstake

        vm.startPrank(user);
        staking.unStake(200e18);
        vm.stopPrank();

        assertEq(mockToken.balanceOf(user), 3e18 + 5e17 + 200e18);

        (
            uint256 totalStakedAmountOfUser,
            ,
            ,
            uint256 lastUpdatedAtOfUser,
            uint256 lastClaimtimeOfUser,
            uint256 rewardDebtOfUseer,
            ,

        ) = staking.userInfo(user);

        assertEq(totalStakedAmountOfUser, 0);
        assertEq(lastUpdatedAtOfUser, block.timestamp);
        assertEq(lastClaimtimeOfUser, block.timestamp);
        assertEq(rewardDebtOfUseer, 0);
    }
}
