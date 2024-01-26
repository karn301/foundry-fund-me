// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner(); //custom error

contract FundMe {
    using PriceConverter for uint256; // all uint256 have access to functions in library
    // uint256 public myValue = 1;
    uint256 public constant MINIMUM_USD = 5e18;
    // just like wallets, contracts can also hold funds (if wallet address)
    AggregatorV3Interface private s_priceFeed;
    address[] private s_funders;

    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_owner;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent $5
        // 1. how do we send ETH to this contract

        // myValue = myValue + 2; // if get a revert statement this value will get reverted or resetted to its initial value or rather previous value
        // require(msg.value > 1e18, "didn't send enough ETH"); //1e18 = 1 ETH = 1000000000000000000 (Wei)= 1 * 10 ** 18 // force users to send at least 1 ether

        // msg.value.getConversionRate(); //implicit calling

        //here the msg.value is in terms of wei or ETH amd minimumUsd is in terms of USD, so here chainlink or Oracle comes into picture
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        );

        // what is a revert?
        // undo any actions that have been done, and send the remaining gas back
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 funderslength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < funderslength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); //not calling  function thats why ("")
        require(callSuccess, "Call-failed");
    }

    function withdraw() public onlyOwner {
        // first onlyOwner will execute

        //for loop
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        // actually withdraw the funds 3 ways
        // 1. transfer

        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance); //if fails throws error

        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // returns boolean value if fails
        // require(sendSuccess, "Send-failed");

        // 3. call  //forwards all gas or set gas , returns bool
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); //not calling  function thats why ("")
        require(callSuccess, "Call-failed");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Must be owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // if this line appears first then it means the code in the function will be first executed and then the modifier
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions(Getters)
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
