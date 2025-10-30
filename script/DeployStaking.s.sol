//SPDX-License-Identifier:MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {MockToken} from "../test/MockToken.sol";

contract DeployStaking is Script {
    Staking staking;
    MockToken mockToken;

    function run() external {
        vm.startBroadcast();
        mockToken = new MockToken();
        staking = new Staking(address(mockToken), msg.sender);

        // adding initial liquidity to contract
        mockToken.transfer(address(staking), 10000e18);

        vm.stopBroadcast();
    }
}
