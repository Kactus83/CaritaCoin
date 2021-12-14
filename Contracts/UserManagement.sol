// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Interfaces/IBEP20.sol";
import "./Interfaces/IConfig.sol";
import "./Context.sol";
import "./Interfaces/ICoin.sol";

contract UserManagement is ContextMaster {

    address[] public userAddresses;

    mapping (address => bool) internal authorizations;
    mapping (address => uint) userRole;
    mapping (address => bool) isRegistred;
    mapping (address => userDetails) userList;

    struct userDetails {
        address userAddress;
        uint256 userBalance;
        uint256 totalDonation;
        uint256 totalCharityBuyAmount;
        uint256 role;   // 0 - user without  contract approvation || 1 - user with contract approvation || 2 - authorized contract || 3 - admin
    }
    
    // Events

    event OwnershipTransferred(address owner);
    event UserStatsUpdated(address user);
    event UserCreated(address user);
    event UserRoleUpdated(address user, uint role);

    // Initialize Parameters

    constructor() {
  
        TOKEN = address(msg.sender);
        
        authorizations[owner] = true; 
        authorizations[TOKEN] = true;  
        userRole[owner] = 3;
        userList[owner].userAddress = address(owner);
        userList[owner].userBalance = 0;
        userList[owner].totalDonation = 999999999999999;
        userList[owner].totalCharityBuyAmount = 999999999999999;
        userList[owner].role = 3;
        userAddresses.push(owner);  
    }

    // Modifiers

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    modifier authorizedContract() {
        require(userRole[msg.sender] == 1); _;
    }

    // Read Functions

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function getUserBalance(address _userAddress) external view returns(uint _userBalance) {
        _userBalance = userList[_userAddress].userBalance;
        return _userBalance;
    }

    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation) {
        _userTotalDonation = userList[_userAddress].totalDonation;
        return _userTotalDonation;
    }

    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount) {
        _userTotalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount;
        return _userTotalCharityBuyAmount;
    }

    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }

    // Edit Functions
    
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function editUserRole (address _address, uint _role) public authorized {
        userList[_address].role = _role;
        userRole[_address] = _role;
        emit UserRoleUpdated(_address, _role);
    }
  
    function contractEditUserRole (address _address, uint _role) external authorizedContract {
        userList[_address].role = _role;
        userRole[_address] = _role;
        emit UserRoleUpdated(_address, _role);
    }

    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external authorizedContract {
        if (isRegistred[_userAddress] == true) {
            updateUser(_userAddress, bnbDonationAmount, tokenBuyAmount);
        }
        else {
            addUser(_userAddress);
         }
    }
      
    function addUser(address _userAddress) internal {
        require(isRegistred[_userAddress] == false);
        userRole[_userAddress] = 0;
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userBalance = iToken.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = 0;
        userList[_userAddress].totalCharityBuyAmount = 0;
        userList[_userAddress].role = 0;
        userAddresses.push(_userAddress);
        isRegistred[_userAddress] = true;
        emit UserCreated(_userAddress);
    }

    function updateUser(address _userAddress, uint _BnbDonationAmount, uint _TokenBuyAmount) internal {
        require(isRegistred[_userAddress] == true);
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userBalance = iToken.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = userList[_userAddress].totalDonation + _BnbDonationAmount;
        userList[_userAddress].totalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount + _TokenBuyAmount;
        emit UserStatsUpdated(_userAddress);
    }

    // Initial Variables Edition

    function initialVariableEdition(address a1, address a2, address a3, address a4, address a5) external {
        require(msg.sender == TOKEN);
        dexPair = a1;
        charityVaultAddress = a2;
        preSalesAddress = a3;
        distributorAddress = a4;
        owner = a5;

        iPreSaleConfig = IPreSale(a3);
        iCharityVault = ICharityVault(a2);
        iCharityVault.adminEditSettings();
        iPreSaleConfig.adminEditSettings();
    }
}
