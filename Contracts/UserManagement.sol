// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract UserManagement {
    address internal owner;
    mapping (address => bool) internal authorizations;

    address _token;

    struct userDetails {
        address userAddress;
        uint256 userBalance;
        uint256 totalDonation;
        uint256 totalCharityBuyAmount;
        uint256 role;   // 0 - normal user || 1 - authorized contract ||
    }

    mapping (address => uint) userRole;
    mapping (address => bool) isRegistred;
    mapping (address => userDetails) userList;
    address[] public userAddresses;
    
    IBEP20 Token;  

    constructor(address _owner, address _tokenAddress) {
        owner = _owner;
        authorizations[_owner] = true;
        _token = _tokenAddress;    
        Token = IBEP20(_token);    
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

    // Functions

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function editUserRole (address _address, uint _role) public authorized {
        userList[_address].role = _role;
        userRole[_address] = _role;
    }
  
    function contractEditUserRole (address _address, uint _role) external authorizedContract {
        userList[_address].role = _role;
        userRole[_address] = _role;
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
        userList[_userAddress].userBalance = Token.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = 0;
        userList[_userAddress].totalCharityBuyAmount = 0;
        userList[_userAddress].role = 0;
        userAddresses.push(_userAddress);
        isRegistred[_userAddress] = true;
    }

    function updateUser(address _userAddress, uint _BnbDonationAmount, uint _TokenBuyAmount) internal {
        require(isRegistred[_userAddress] == true);
        userList[_userAddress].userAddress = address(_userAddress);
        userList[_userAddress].userBalance = Token.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = userList[_userAddress].totalDonation + _BnbDonationAmount;
        userList[_userAddress].totalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount + _TokenBuyAmount;
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


    event OwnershipTransferred(address owner);
}
