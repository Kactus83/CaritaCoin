// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUserManagement {
    
    // Read Functions

    function isOwner(address account) public view returns (bool);
    function isAuthorized(address adr) public view returns (bool;
    function getUserBalance(address _userAddress) external view returns(uint _userBalance);
    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation);
    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount);
    function getAllUsers() public view returns (address[] memory);

   // Edit Functions

    function contractEditUserRole (address _address, uint _role) external authorizedContract;
    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external authorizedContract;
}
