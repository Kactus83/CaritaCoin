// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./libraries/SafeMath.sol";
import "./interfaces/IDEXFactory+IDEXRouter.sol";
import "./interfaces/IBEP20.sol";

contract PreSale {
    using SafeMath for uint256;


    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    uint256 constant private MAX_INT = 2**256 - 1;

    address public wbnbAddress;
    address public tokenAddress;
    address public pairAddress;
    address public routerAddress;
    address private userManagementAddress;

    uint tokensSold;

    // Initialize Parameters

    constructor (address _tokenAddress, address _wbnbAddress,  address _pairAddress, address _routerAddress, address _userManagementAddress) {

        tokenAddress = _tokenAddress;
        wbnbAddress = _wbnbAddress;
        pairAddress = _pairAddress;
        routerAddress = _routerAddress;
        userManagementAddress = _userManagementAddress;
    }

    // Initialize Interfaces

    IUserManagement USERMANAGEMENT = IUserManagement(tokenAddress);
    IDEXRouter ROUTER = IDEXRouter(routerAddress);
    IBEP20 TOKEN = IBEP20(tokenAddress);  
    IBEP20 LPTOKEN = IBEP20(pairAddress);
    IBEP20 WBNB = IBEP20(wbnbAddress);

    // Modifiers 

    modifier onlyToken() {
        require(msg.sender == tokenAddress); _;
    }

    // View Functions
    
    function getEstimatedTokenForBNB(uint buyAmountInWei) public view  returns (uint[] memory bnbQuote) {
        bnbQuote = ROUTER.getAmountsIn(buyAmountInWei, getPathForTokenToBNB());
    }

    // Utility Functions

    function getPathForTokenToBNB() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = wbnbAddress;
        
        return path;
    }

    function checkAmountValidity (uint buyAmountInWei) internal view returns(bool checkResult) {
        try ROUTER.getAmountsIn(buyAmountInWei, getPathForTokenToBNB()) {
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

        uint amountOfToken = ROUTER.getAmountsIn(msg.value, getPathForTokenToBNB())[1];

        require(TOKEN.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(address(msg.sender), amountOfToken);
        tokensSold += amountOfToken;

        require(TOKEN.transfer(address(msg.sender), amountOfToken));
        USERMANAGEMENT.updateUserGiftStats(address(msg.sender), msg.value, amountOfToken);
    }

    function externalCharityBuyForLiquidity(address _sender, uint _amount) external {
        require(checkAmountValidity(_amount) == true, "Amount is not valide");

        uint amountOfToken = ROUTER.getAmountsIn(_amount, getPathForTokenToBNB())[1];

        require(TOKEN.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(_sender, amountOfToken);
        tokensSold += amountOfToken;

        require(TOKEN.transfer(_sender, amountOfToken));
        USERMANAGEMENT.updateUserGiftStats(address(_sender), _amount, amountOfToken);
    }

    // Settings Functions

    function endSale(address _sender) external  onlyToken{
        require(USERMANAGEMENT.isAuthorized(_sender) == true);
        require(TOKEN.transfer(tokenAddress, TOKEN.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function changeToken (address _newTokenAddress, address _newPairAddress) external  onlyToken {
        require(USERMANAGEMENT.isAuthorized(msg.sender) == true);
        tokenAddress = _newTokenAddress;
        pairAddress = _newPairAddress;
    }

    function changeRouter (address _newRouterAddress) external  onlyToken{
        require(USERMANAGEMENT.isAuthorized(msg.sender) == true);
        routerAddress = _newRouterAddress;
    }

    // Events

    event Sold(address buyer, uint256 amount);
}