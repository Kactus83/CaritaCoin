pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT

import "./Interfaces/IBEP20.sol";
import "./Interfaces/IConfig.sol";
import "./Context.sol";

contract CharityVault is ContextSlave {
    
    // Initialize Parameters

    constructor() {
        TOKEN = address(msg.sender);
    }
 
    // Modifiers 

    modifier onlyToken() {
        require(msg.sender == TOKEN); _;
    }


    // Settings Functions

    function setUserManagementAddress(address _newAddress) external onlyToken {
        userManagementAddress = _newAddress;
    }
}