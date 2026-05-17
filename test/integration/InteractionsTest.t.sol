// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/interactions.s.sol";

contract InteractionTest is Test {
    FundMe fundme;
    address USER = makeAddr("Copernicium282");
    uint256 INIT_BALANCE = 10 ether;
    uint256 SEND_VAL = 1 ether;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundme = deploy.run();
        vm.deal(USER, INIT_BALANCE);
    }

    function testUserCanFundInteractions() public {
        // Fund
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundme));

        address funder = fundme.getFunder(0); // as the setup function is run first everytime before a test is created, we need to get the first funder here
        assertEq(funder, fundme.getOwner());

        // Withdraw
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundme));

        assert(address(fundme).balance == 0);
    }
}
