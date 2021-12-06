// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface IUserManagement {
    
    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external;

    function getUserBalance(address _userAddress) external view returns(uint _userBalance);

    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation);

    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount);

    function getAllUsers() external view returns (address[] memory);

    function isAuthorized(address adr) external view returns (bool);
}
