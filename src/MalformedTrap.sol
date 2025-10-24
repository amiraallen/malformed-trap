// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IBoolWordRegistry {
    function getWords(address trap) external view returns (bytes32[] memory);
}

contract MalformedTrap is ITrap {
    address public constant REGISTRY = 0x0000000000000000000000000000000000000000; // replace with registry address

    function collect() external view returns (bytes memory) {
        bytes32[] memory words = IBoolWordRegistry(REGISTRY).getWords(address(this));
        return abi.encode(words, block.number);
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        returns (bool, bytes memory)
    {
        if (data.length == 0) return (false, "");
        (bytes32[] memory words, uint256 blk) = abi.decode(data[0], (bytes32[], uint256));

        for (uint256 i = 0; i < words.length; i++) {
            bytes32 w = words[i];
            uint8 last = uint8(w[31]);
            if (last > 1) {
                return (true, abi.encode("MALFORMED_BOOLEAN_DETECTED", w, i, blk));
            }
            for (uint256 j = 0; j < 31; j++) {
                if (w[j] != 0x00) {
                    return (true, abi.encode("MALFORMED_BOOLEAN_DETECTED", w, i, blk));
                }
            }
        }
        return (false, "");
    }
}
