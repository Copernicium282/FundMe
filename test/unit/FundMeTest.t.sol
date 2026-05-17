// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("Copernicium282");
    uint INIT_BALANCE = 10 ether;
    uint SEND_VAL = 1 ether;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, INIT_BALANCE);
    }

    function testMinVal() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testSenderIsOwner() public view {
        // assertEq(fundme.i_owner(), address(this)); // me owner of FundMeTest, which is owner of the fundme contract, so we check this
        assertEq(fundme.getOwner(), msg.sender); // now that we deploy using the script, it sets the owner to us instead of FundMeTest, so we can change back
    }
    
    function testPriceFeedVersion() public view {
        uint version = fundme.getVersion();
        assertEq(version, 4); // use --fork-url $SEPOLIA_RPC_URL as the contract for the interface is on sepolia chain, and forge runs a temp anvil chain instead if --fork-url is not used
        // note that this test only works on sepolia as the version on other chains may be different, such as 6 on eth mainnet
    }

    function testFundFailIfBelowMin() public {
        vm.expectRevert();
        fundme.fund();
    }

    modifier funded() {
        vm.prank(USER); // the next tx will be sent by user and not this contract
        fundme.fund{ value: SEND_VAL }();
        _;
    }

    function testFundedTrueIfAboveMin() public funded {
        // uint amtFunded = fundme.getAddressToAmtFunded(address(this)); // since we fund the contract in this code itself and not through a constructor, we need to use address(this) instead of msg.sender
        uint amtFunded = fundme.getAddressToAmtFunded(USER); // we use vm.prank

        assertEq(amtFunded, SEND_VAL);
    }

    function testAddFunderToArray() public funded {
        address funder = fundme.getFunder(0); // as the setup function is run first everytime before a test is created, we need to get the first funder here
        assertEq(funder, USER);
    }

    function testOnlyOwnerWithdraw() public funded {

        vm.expectRevert();
        vm.prank(USER); // this line is skipped
        fundme.cheaperWithdraw(); // reverted as the USER is not the owner
    }

    function testWithdrawWithASingleFunderCheaper() public funded {
        // Arrange
        uint startingOwnerBal = fundme.getOwner().balance;
        uint startingFundMeBal = address(fundme).balance;

        // Act
        vm.prank(fundme.getOwner());
        fundme.cheaperWithdraw();

        // Revert
        uint finalOwnerBal = fundme.getOwner().balance;
        uint finalFundMeBal = address(fundme).balance;

        assertEq(startingFundMeBal + startingOwnerBal, finalOwnerBal);
        assertEq(finalFundMeBal, 0);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numOfFunders = 10;
        uint160 initFunderIndex = 2;
        // uint GAS_PRICE = 1;
        for(uint160 i=initFunderIndex; i<numOfFunders; i++){
            hoax(address(i), INIT_BALANCE);
            fundme.fund{ value: SEND_VAL}();
        }
        uint startingOwnerBal = fundme.getOwner().balance;
        uint startingFundMeBal = address(fundme).balance;

        // Act
        // uint gasStart = gasleft();

        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        // uint gasEnd = gasleft();
        // uint gasConsumed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasConsumed);

        // Revert
        uint finalOwnerBal = fundme.getOwner().balance;
        uint finalFundMeBal = address(fundme).balance;

        assertEq(finalFundMeBal, 0);
        assertEq(startingFundMeBal + startingOwnerBal, finalOwnerBal);
    }
}