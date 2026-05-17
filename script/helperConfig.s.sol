// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Deploy mocks on local change, keep track of its address across different chains
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INIT_PRICE = 2180e8;

    struct NetworkConfig {
        address PriceFeed;
    }

    NetworkConfig public activeNetConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetConfig = getEthConfig();
        } else {
            activeNetConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({PriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});

        return sepoliaConfig;
    }

    function getEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({PriceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});

        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetConfig.PriceFeed != address(0)) {
            // if already deployed, return the deployed one
            return activeNetConfig;
        }

        // deploy mocks and return them

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INIT_PRICE); // uint8 _decimals, int256 _initialAnswer for constructor
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({PriceFeed: address(mockPriceFeed)});

        return anvilConfig;
    }
}
