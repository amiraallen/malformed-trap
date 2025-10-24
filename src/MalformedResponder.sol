// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MalformedResponder {
    address public owner;
    mapping(address => bool) public operators;

    event TrapTriggered(
        string reason,
        bytes32 offendingWord,
        uint256 index,
        uint256 blockNumber,
        address caller
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOperator(address op, bool ok) external onlyOwner {
        operators[op] = ok;
    }

    function handle(bytes calldata payload) external {
        require(operators[msg.sender], "not operator");
        (string memory reason, bytes32 bad, uint256 idx, uint256 blk) =
            abi.decode(payload, (string, bytes32, uint256, uint256));
        emit TrapTriggered(reason, bad, idx, blk, msg.sender);
    }
}
