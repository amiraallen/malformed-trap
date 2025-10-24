# MalformedTrap - Boolean Data Integrity Monitor

A Drosera trap contract that detects malformed boolean values in blockchain storage, ensuring data integrity and preventing potential exploits caused by improperly encoded boolean data.

## Overview

`MalformedTrap` monitors boolean values stored in a registry contract and triggers an alert when it detects malformed boolean data. In Solidity, booleans should be represented as `bytes32` values where all bytes are zero except the last byte, which should be either `0x00` (false) or `0x01` (true). Any deviation from this format indicates potential data corruption or malicious manipulation.

## Use Cases

### 1. **Access Control Verification**
Ensures that boolean flags used for access control (e.g., `isAdmin`, `isApproved`, `hasPermission`) maintain proper encoding and haven't been corrupted by:
- Storage collision attacks
- Malicious upgrades
- Low-level storage manipulation
- Cross-contract storage overwrites

**Example Scenario:** A DeFi protocol uses boolean flags to manage admin privileges. This trap would detect if an attacker attempts to manipulate storage slots to create malformed admin flags that could bypass access checks.

### 2. **State Flag Monitoring**
Monitors critical protocol state flags such as:
- `isPaused` / `isActive` flags in emergency shutdown systems
- `isInitialized` flags in proxy contracts
- `isLocked` flags in reentrancy guards
- `isFinalized` in governance proposals

**Example Scenario:** A lending protocol's pause mechanism relies on a boolean flag. The trap detects if this flag becomes malformed, which could indicate an attempted exploit to bypass emergency controls.

### 3. **Token Transfer Restrictions**
Validates boolean flags that control token transfer permissions:
- Whitelist/blacklist status flags
- Transfer restriction flags
- Vesting or lock status indicators
- KYC/AML compliance flags

**Example Scenario:** A security token uses boolean flags to enforce transfer restrictions. Malformed flags could allow unauthorized transfers, which this trap would immediately detect.

### 4. **Voting and Governance Integrity**
Ensures the integrity of boolean values in governance systems:
- Voter eligibility flags
- Proposal execution status
- Vote casting records
- Quorum achievement flags

**Example Scenario:** A DAO governance system tracks whether addresses have voted. Malformed voting flags could enable double-voting attacks, which this trap would identify.

### 5. **Oracle Data Validation**
Monitors boolean responses from oracle systems:
- Price feed validity flags
- Data staleness indicators
- Oracle active/inactive status
- Consensus achievement flags

**Example Scenario:** A DeFi protocol relies on oracle boolean flags to determine if price data is fresh. Malformed flags could cause the protocol to accept stale prices, leading to arbitrage opportunities.

### 6. **Multi-Signature Wallet Security**
Validates boolean approval flags in multi-signature systems:
- Transaction approval status
- Signer authorization flags
- Execution confirmation flags

**Example Scenario:** A multi-sig wallet uses boolean flags to track approvals. Malformed flags could trick the system into executing transactions without proper authorization.

### 7. **Protocol Upgrade Guards**
Monitors boolean flags that control upgrade mechanisms:
- Upgrade authorization flags
- Implementation validity markers
- Timelock status indicators

**Example Scenario:** A proxy contract uses a boolean to indicate if an upgrade has been authorized. A malformed flag could be exploited to bypass upgrade restrictions.

### 8. **Flash Loan Protection**
Tracks boolean flags used in flash loan protection mechanisms:
- Reentrancy detection flags
- Same-block interaction prevention
- Flash loan active indicators

**Example Scenario:** A protocol uses boolean flags to prevent flash loan attacks. Malformed flags could disable these protections without triggering normal security checks.

## How It Works

### Data Collection (`collect`)
The trap periodically queries the `BoolWordRegistry` contract to retrieve all boolean values (stored as `bytes32`) associated with this trap instance, along with the current block number.
```solidity
function collect() external view returns (bytes memory) {
    bytes32[] memory words = IBoolWordRegistry(REGISTRY).getWords(address(this));
    return abi.encode(words, block.number);
}
```

### Validation Logic (`shouldRespond`)
The trap examines each `bytes32` value and checks for two types of malformations:

1. **Invalid Last Byte**: The last byte (byte 31) must be either `0x00` or `0x01`. Values of `0x02` or higher are invalid.
2. **Non-Zero Padding**: The first 31 bytes must all be zero. Any non-zero value in these positions indicates corruption.
```solidity
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
        
        // Check if last byte is greater than 1 (invalid boolean)
        if (last > 1) {
            return (true, abi.encode("MALFORMED_BOOLEAN_DETECTED", w, i, blk));
        }
        
        // Check if any of the first 31 bytes are non-zero (invalid padding)
        for (uint256 j = 0; j < 31; j++) {
            if (w[j] != 0x00) {
                return (true, abi.encode("MALFORMED_BOOLEAN_DETECTED", w, i, blk));
            }
        }
    }
    
    return (false, "");
}
```

### Alert Payload
When a malformed boolean is detected, the trap returns:
- `"MALFORMED_BOOLEAN_DETECTED"` - Alert identifier
- The malformed `bytes32` value
- The index position of the malformed value
- The block number when detected

## Integration

### Prerequisites
- A `BoolWordRegistry` contract deployed at the specified `REGISTRY` address
- The registry must implement `getWords(address trap)` returning `bytes32[]` of boolean values to monitor

### Deployment
1. Deploy the `BoolWordRegistry` contract
2. Update the `REGISTRY` constant with the deployed registry address:
```solidity
address public constant REGISTRY = 0x1234567890123456789012345678901234567890; // Your registry address
```
3. Deploy the `MalformedTrap` contract
4. Register the boolean storage slots you want to monitor in the registry

### Example Registry Interface
```solidity
interface IBoolWordRegistry {
    function getWords(address trap) external view returns (bytes32[] memory);
}
```

## Contract Code
```solidity
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
```

## Security Considerations

- **Gas Efficiency**: The trap iterates through all registered boolean values. Ensure the registry doesn't return an excessive number of values to avoid out-of-gas errors.
- **False Positives**: The trap is strict about boolean encoding. Ensure monitored storage slots genuinely contain boolean values.
- **Response Actions**: Connect this trap to appropriate response mechanisms (e.g., pause protocols, trigger alerts, execute emergency procedures) based on your security requirements.
- **Registry Trust**: The trap relies on the registry contract for data. Ensure the registry is secure and trustworthy.

## Testing

Example test cases to implement:
- Valid boolean values (`0x00...00` and `0x00...01`)
- Invalid last byte (`0x00...02`, `0x00...FF`)
- Invalid padding (`0x01...00`, `0xFF...01`)
- Empty data array
- Large arrays of boolean values
