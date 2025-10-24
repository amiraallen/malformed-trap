// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BoolWordRegistry {
    mapping(address => bool) public operators;
    mapping(address => bytes32[]) public latestWords;

    modifier onlyOperator() {
        require(operators[msg.sender], "not operator");
        _;
    }

    function setOperator(address op, bool ok) external {
        operators[op] = ok;
    }

    function pushWords(address trap, bytes32[] calldata words) external onlyOperator {
        latestWords[trap] = words;
    }

    function getWords(address trap) external view returns (bytes32[] memory) {
        return latestWords[trap];
    }
}
