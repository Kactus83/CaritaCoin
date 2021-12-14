pragma solidity >=0.8.9;
// SPDX-License-Identifier: MIT

import "./Interfaces/IDEXFactory+IDEXRouter.sol";
import "./Interfaces/IBEP20.sol";
import "./Interfaces/IPreSale.sol";
import "./Interfaces/IUserManagement.sol";
import "./Interfaces/IConfig.sol";
import "./Interfaces/ICharityVault.sol";
import "./Interfaces/ICoin.sol";


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

    IDEXRouter iRouter;
    IPreSale iPreSaleConfig;
    IUserManagement iUserManagement;
    IBEP20 iToken;
    ICharityVault iCharityVault;
    ICoin iCoin;

}

contract ContextMaster is Context {


    // Addresses from Token Creation

    address public TOKEN;
    address public dexPair;
    address public userManagementAddress = address(this);
    address public charityVaultAddress;
    address public preSalesAddress;
    address public distributorAddress;

    // Admin Settings

    function changeInitialVariables(address _BUSD, address _WBNB, address _ROUTER, address _DEVWALLET, address _TOKEN, address _dexPair, address _charityVaultAddress, address _preSalesAddress, address _distributorAddress) public {

        BUSD = _BUSD;
        WBNB = _WBNB;
        ROUTER = _ROUTER;
        DEVWALLET = _DEVWALLET;
        TOKEN = _TOKEN;
        dexPair = _dexPair;
        userManagementAddress = address(this);
        charityVaultAddress = _charityVaultAddress;
        preSalesAddress = _preSalesAddress;
        distributorAddress = _distributorAddress; 

        iRouter = IDEXRouter(_ROUTER);
        iPreSaleConfig = IPreSale(_preSalesAddress);
        iUserManagement = IUserManagement(address(this));
        iToken = IBEP20(_TOKEN);
        iCharityVault = ICharityVault(_charityVaultAddress);
        iCoin = ICoin(_TOKEN);

        iCoin.adminEditSettings();
        iCharityVault.adminEditSettings();
        iPreSaleConfig.adminEditSettings();
    }


    // Interface View Function 
    
    function getOwnerAddress() external view returns(address) { return owner;}
    function getPairAddress() external view returns(address) { return dexPair;}
    function getTokenAddress() external view returns(address) { return address(this);}
    function getWBNBAddress() external view returns(address) { return WBNB;}
    function getBUSDAddress() external view returns(address) { return BUSD;}
    function getRouterAddress() external view returns(address) { return ROUTER;}
    function getDevWalletAddress() external view returns(address) { return DEVWALLET;}
    function getUserManagementAddress() external view returns(address) { return userManagementAddress;}
    function getDistributorAddress() external view returns(address) { return distributorAddress;}    
    function getCharityVaultAddress() external view returns(address) { return charityVaultAddress;}
    function getPreSalesAddress() external view returns(address) { return preSalesAddress;} 
}

contract ContextSlave is Context {

    // Addresses from Token Creation

    address public TOKEN;
    address public dexPair;
    address public userManagementAddress;
    address public charityVaultAddress;
    address public preSalesAddress;
    address public distributorAddress;

    // Slave Edit Function

    function adminEditSettings() external  {
        require(msg.sender == userManagementAddress);
        IConfig iConfig = IConfig(userManagementAddress);
    
        owner = iConfig.getOwnerAddress();
        TOKEN = iConfig.getTokenAddress();
        dexPair = iConfig.getPairAddress();
        userManagementAddress = iConfig.getUserManagementAddress();
        charityVaultAddress = iConfig.getCharityVaultAddress();
        preSalesAddress = iConfig.getPreSalesAddress();
        distributorAddress = iConfig.getDistributorAddress();
        BUSD = iConfig.getBUSDAddress();
        WBNB = iConfig.getWBNBAddress();
        ROUTER = iConfig.getRouterAddress();
        DEVWALLET = iConfig.getDevWalletAddress();   
    }
}