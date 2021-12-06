// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract PreSale is IPreSale {
    using SafeMath for uint256;


    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    address public WBNB;
    address public tokenAddress;
    address public pairAddress;
    address public routerAddress;
    uint tokensSold;

    uint256 constant private MAX_INT = 2**256 - 1;
    
    event Sold(address buyer, uint256 amount);

    constructor (address _tokenAddress, address _wbnbAddress,  address _pairAddress, address _routerAddress) {

        tokenAddress = _tokenAddress;
        WBNB = _wbnbAddress;
        pairAddress = _pairAddress;
        routerAddress = _routerAddress;
    }

    IUserManagement userAdministration = IUserManagement(tokenAddress);
    IDEXRouter pancakeRouter = IDEXRouter(routerAddress);
    IBEP20 tokenContract = IBEP20(tokenAddress);  
    IBEP20 lpToken = IBEP20(pairAddress);
    IBEP20 wbnbContract = IBEP20(WBNB);

        
    modifier onlyToken() {
        require(msg.sender == tokenAddress); _;
    }

    function getPathForTokenToBNB() internal view returns (address[] memory) {

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WBNB;
        
        return path;
    }
    
    function getEstimatedTokenForBNB(uint buyAmountInWei) external view override returns (uint[] memory bnbQuote) {

        bnbQuote = pancakeRouter.getAmountsIn(buyAmountInWei, getPathForTokenToBNB());
    }

    function checkAmountValidity (uint buyAmountInWei) internal view returns(bool checkResult) {
    
        try pancakeRouter.getAmountsIn(buyAmountInWei, getPathForTokenToBNB()) {
            return true;        
            }
        catch {
            return false;
            }
    }

    function charityBuyForLiquidity(address _sender, uint _amount) external override {
        require(checkAmountValidity(_amount) == true, "Amount is not valide");

        uint amountOfToken = pancakeRouter.getAmountsIn(_amount, getPathForTokenToBNB())[1];

        require(tokenContract.balanceOf(address(this)) >= amountOfToken, "There is not enought tokens");

        emit Sold(_sender, amountOfToken);
        tokensSold += amountOfToken;

        require(tokenContract.transfer(_sender, amountOfToken));
        userAdministration.updateUserGiftStats(address(_sender), _amount, amountOfToken);
    }

    function endSale(address _sender) external override onlyToken{
        require(userAdministration.isAuthorized(_sender) == true);
        require(tokenContract.transfer(tokenAddress, tokenContract.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function changeToken (address _newTokenAddress, address _newPairAddress) external override onlyToken {
        require(userAdministration.isAuthorized(msg.sender) == true);
        tokenAddress = _newTokenAddress;
        pairAddress = _newPairAddress;
    }

    function changeRouter (address _newRouterAddress) external override onlyToken{
        require(userAdministration.isAuthorized(msg.sender) == true);
        routerAddress = _newRouterAddress;
    }

}