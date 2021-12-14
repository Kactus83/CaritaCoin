// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;


interface IConfig {

    function getOwnerAddress() external view returns(address);
    function getPairAddress() external view returns(address);
    function getTokenAddress() external view returns(address);
    function getWBNBAddress() external view returns(address);
    function getBUSDAddress() external view returns(address);
    function getRouterAddress() external view returns(address);
    function getDevWalletAddress() external view returns(address);
    function getUserManagementAddress() external view returns(address);
    function getDistributorAddress() external view returns(address);    
    function getCharityVaultAddress() external view returns(address);
    function getPreSalesAddress() external view returns(address);

}