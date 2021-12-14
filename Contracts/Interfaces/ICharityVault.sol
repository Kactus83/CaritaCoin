pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT


interface ICharityVault {
    
    // Settings Functions
    
    function setUserManagementAddress(address _newAddress) external;
    
    // Slave Edit Function

    function adminEditSettings() external; 
}