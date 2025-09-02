// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract MalformedTrap is ITrap {
    constructor() {}
    
    function collect() external view returns (bytes memory) {
        return abi.encode(msg.sender, block.timestamp);
    }
    
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        bool suspicious = false;
        bytes memory responseData = "";
        
        for (uint256 i = 0; i < data.length; i++) {
            bytes calldata item = data[i];
            
            if (item.length >= 32) {
                bool hasNonZeroBytes = false;
                uint256 lastByteValue = 0;
                
                for (uint256 j = item.length - 32; j < item.length - 1; j++) {
                    if (item[j] != 0) {
                        hasNonZeroBytes = true;
                        break;
                    }
                }
                
                lastByteValue = uint256(uint8(item[item.length - 1]));
                
                if (hasNonZeroBytes || lastByteValue > 1) {
                    suspicious = true;
                    responseData = abi.encode(
                        "MALFORMED_BOOLEAN_DETECTED",
                        lastByteValue,
                        i
                    );
                    break;
                }
            }
        }
        
        return (suspicious, responseData);
    }
}