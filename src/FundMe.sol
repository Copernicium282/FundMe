// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // We introduce a withdrawal epoch tracker. Instead of looping to reset everyone's balance to 0 (which costs O(N) gas and could get stuck), 
    // we use a nested mapping. When the owner withdraws, we increment the epoch. This instantly resets everyone's balance to 0 in O(1) gas!
    uint256 private s_epoch;
    mapping(uint256 => mapping(address => uint256)) private s_epochToAddressToAmountFunded;
    address[] private s_funders;

    // We make these variables immutable. Because they are only set in the constructor and never change, 
    // declaring them immutable stores their values in the contract bytecode instead of storage, saving massive gas!
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; 
    AggregatorV3Interface private immutable i_PriceFeed;

    constructor(address PriceFeed) {
        i_owner = msg.sender;
        i_PriceFeed = AggregatorV3Interface(PriceFeed); // Set the immutable price feed address
    }

    function fund() public payable {
        require(msg.value.getConversionRate(i_PriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_epochToAddressToAmountFunded[s_epoch][msg.sender] += msg.value; // Store the deposit mapping under the current epoch
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = i_PriceFeed; // Read from our gas-efficient immutable variable
        return priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function cheaperWithdraw() public onlyOwner {
        // Incrementing the epoch is an extremely elegant O(1) gas optimization. It voids all balances for the current epoch,
        // effectively resetting all funder mappings to 0 instantly without using a loops or wasting gas.
        s_epoch++;
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    // view / pure functions (getters)
    function getAddressToAmtFunded(
        address fundingAddress
    ) external view returns(uint) {
        // Retrieve the balance of the address corresponding to the active epoch
        return s_epochToAddressToAmountFunded[s_epoch][fundingAddress];
    }

    function getFunder(
        uint index
    ) external view returns(address) {
        return s_funders[index];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly