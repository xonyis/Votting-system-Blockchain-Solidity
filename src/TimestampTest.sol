// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimestampTest {
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp + 2417100;
    }

    function isTimeAfter(uint256 timestamp) public view returns (bool, uint256) {
        return (block.timestamp > timestamp, block.timestamp);
    }

    function compareWithClosingTime(uint256 closingTime) public view returns (bool, uint256, uint256) {
        return (block.timestamp >= closingTime, block.timestamp, closingTime);
    }
}