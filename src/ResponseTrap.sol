// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ResponseTrap {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event TrapTriggered(address indexed wallet, bool suspicious, bytes responseData);
    
    function processResponse(
        bool suspicious,
        bytes calldata responseData
    ) external onlyOwner {
        emit TrapTriggered(msg.sender, suspicious, responseData);
    }
}