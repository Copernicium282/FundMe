// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // non-real tx
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetConfig();

        // real tx after vm.Broadcast starts
        vm.startBroadcast();
        FundMe fundme = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundme;
    }
}
