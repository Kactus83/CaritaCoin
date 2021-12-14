// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Libraries/SafeMath.sol";
import "./Interfaces/IUserManagement.sol";
import "./Interfaces/IDEXFactory+IDEXRouter.sol";
import "./Interfaces/IBEP20.sol";
import "./Interfaces/IConfig.sol";
import "./Context.sol";

contract PreSale is ContextSlave {
    using SafeMath for uint256;

    uint tokensSold;

    // Initialize Parameters

    constructor() {

        TOKEN = address(msg.sender);
    }

    // Modifiers 

    modifier onlyToken() {
        require(msg.sender == TOKEN); _;
    }

    // View Functions
    
    function getEstimatedTokenForBNB(uint256 buyAmountInWei) external view  returns (uint256) {
        uint256 bnbQuote;
        bnbQuote = iRouter.getAmountsOut(buyAmountInWei, getPathForWBNBToToken())[1];
        return bnbQuote;
    }

    // Utility Functions

    receive() external payable {}

    function getPathForWBNBToToken() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = TOKEN;
        
        return path;
    }

    function checkAmountValidity (uint buyAmountInWei) internal view returns(bool checkResult) {
        try iRouter.getAmountsOut(buyAmountInWei, getPathForWBNBToToken()) {
            checkResult = true;
            return checkResult;        
            }
        catch {
            checkResult = false;
            return checkResult;
            }
    }

    // Buy Functions

    function CharityBuyForLiquidity() public payable {

        require(checkAmountValidity(msg.value) == true, "Amount is not valide");

        uint amountOfToken = iRouter.getAmountsOut(msg.value, getPathForWBNBToToken())[1];

        require(iToken.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(address(msg.sender), amountOfToken);
        tokensSold += amountOfToken;

        require(iToken.transfer(address(msg.sender), amountOfToken));
        iUserManagement.updateUserGiftStats(address(msg.sender), msg.value, amountOfToken);
    }

    function externalCharityBuyForLiquidity(address _sender, uint _amount) external {
        require(checkAmountValidity(_amount) == true, "Amount is not valide");

        uint amountOfToken = iRouter.getAmountsOut(_amount, getPathForWBNBToToken())[1];

        require(iToken.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(_sender, amountOfToken);
        tokensSold += amountOfToken;

        require(iToken.transfer(_sender, amountOfToken));
        iUserManagement.updateUserGiftStats(address(_sender), _amount, amountOfToken);
    }

    // Settings Functions

    function endSale(address _sender) external  onlyToken{
        require(iUserManagement.isAuthorized(_sender) == true);
        require(iToken.transfer(TOKEN, iToken.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function setUserManagementAddress(address _newAddress) external onlyToken {
        userManagementAddress = _newAddress;
    }

    // Events

    event Sold(address buyer, uint256 amount);
}
