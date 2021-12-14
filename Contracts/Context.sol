pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT

contract Context {

    // Constant Addresses & Parameters

    address public owner;
    
    address public BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public DEVWALLET = 0xF53c251ACbfc7Df58A2f47F063af69A3ED897042;


    uint256 constant public MAX_INT = 2**256 - 1;

    // Initialize Variables

    address public dexPair;
    address public userManagementAddress;
    address public charityVaultAddress;
    address public preSalesAddress;

    IDEXRouter iRouter;
    IPreSale iPreSaleConfig;
    IUserManagement iUserManagement;

    constructor() {

        // Create Contracts

        UserManagement userManagement = new UserManagement();
        CharityVault charityVault = new CharityVault();
        PreSale preSales = new PreSale();
        userManagementAddress = address(userManagement);
        charityVaultAddress = address(charityVault);
        preSalesAddress = address(preSales);

        // Set Interfaces

        iRouter = IDEXRouter(ROUTER);
        iPreSaleConfig = IPreSale(address(preSalesAddress));
        iUserManagement = IUserManagement(address(userManagementAddress));
        
        // Create Pair and Set Owner

        dexPair = IDEXFactory(iRouter.factory()).createPair(WBNB, address(this));
        owner = msg.sender;
    }