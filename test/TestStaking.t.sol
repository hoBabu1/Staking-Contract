//SPDX-License-Identifier : MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {MockToken} from "./MockToken.sol";

contract TestStaking is Test {
    Staking staking;
    MockToken mockToken;

    address owner = makeAddr("Owner");
    address user = makeAddr("User1");
    address user2 = makeAddr("User2");

    uint256 initalAmount = 100e18;

    function setUp() external {
        vm.startPrank(owner);
        mockToken = new MockToken();
        staking = new Staking(address(mockToken));
        mockToken.transfer(user, initalAmount);
        vm.stopPrank();
    }

    /**
     *  Assuming that  pre - registration is required for referring
     */

    function test_stake() public {
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
    }

    // User 2 Will stake with a refferal of User1
}
