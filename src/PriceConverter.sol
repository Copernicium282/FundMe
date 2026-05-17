// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface PriceFeed) internal view returns (uint256) {
        // Sepolia ETH / USD Address
        // https://docs.chain.link/data-feeds/price-feeds/addresses
        AggregatorV3Interface priceFeed = AggregatorV3Interface(PriceFeed);
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData(); // Fetch the complete round data from the oracle to validate its health

        // Security check: Ensure the returned price is positive. An invalid or zero price could break math.
        require(answer > 0, "Chainlink price feed returned invalid price");

        // Security check: Ensure the oracle round is fully completed and finalized.
        require(updatedAt != 0, "Round not complete");

        // Security check: Prevent using stale or outdated prices by matching the answered round ID.
        require(answeredInRound >= roundId, "Stale price");

        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface PriceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(PriceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}
