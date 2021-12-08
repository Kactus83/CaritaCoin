pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT


/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                   CARITAS Coin Token                                    //
//                                         TEST                                            //
//                                                                                         //
//                                                                                         //
//                   DESCRIPTION A REFAIRE                                                 //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//  You can help us sending tips to the developpers wallet :)                              //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

library SafeMath {



    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        //assert(a == b * c + a % b); // There is no case in which this doesn't hold ---------------------------------------------

        return c;
    }
}


interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract UserManagement {

    address internal owner;
    address tokenAddress;
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

    constructor(address _owner, address _tokenAddress) {
        owner = _owner;
        tokenAddress = _tokenAddress;   
        authorizations[_owner] = true;  
        userRole[_owner] = 3;
        userList[_owner].userAddress = address(_owner);
        userList[_owner].userBalance = 0;
        userList[_owner].totalDonation = 999999999999999;
        userList[_owner].totalCharityBuyAmount = 999999999999999;
        userList[_owner].role = 3;
        userAddresses.push(_owner);  
    }

    // Initialize Interfaces

    IBEP20 Token = IBEP20(tokenAddress); 

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
        userList[_userAddress].userBalance = Token.balanceOf(_userAddress);
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
        userList[_userAddress].userBalance = Token.balanceOf(_userAddress);
        userList[_userAddress].totalDonation = userList[_userAddress].totalDonation + _BnbDonationAmount;
        userList[_userAddress].totalCharityBuyAmount = userList[_userAddress].totalCharityBuyAmount + _TokenBuyAmount;
        emit UserStatsUpdated(_userAddress);
    }

}

interface IUserManagement {
    
    // Read Functions

    function isOwner(address account) external view returns (bool);
    function isAuthorized(address adr) external view returns (bool);
    function getUserBalance(address _userAddress) external view returns(uint _userBalance);
    function getUserTotalDonation(address _userAddress) external view returns(uint _userTotalDonation);
    function getUserTotalCharityBuyAmount(address _userAddress) external view returns(uint _userTotalCharityBuyAmount);
    function getAllUsers() external view returns (address[] memory);

   // Edit Functions

    function contractEditUserRole (address _address, uint _role) external;
    function updateUserGiftStats(address _userAddress, uint bnbDonationAmount, uint tokenBuyAmount) external;
}

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

    receive () external payable {}

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

interface IPreSale {


    // View Functions
    
    function getEstimatedTokenForBNB(uint buyAmountInWei) external view  returns (uint[] memory bnbQuote);

    // Buy Functions

    function externalCharityBuyForLiquidity(address _sender, uint _amount) external;

    // Settings Functions

    function endSale(address _sender) external;
    function changeToken (address _newTokenAddress, address _newPairAddress) external;
    function changeRouter (address _newRouterAddress) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
 
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract CharityVault {
    
    address vaultAddress = address(this);

}


contract CARITEST1 is IBEP20 {
    using SafeMath for uint256;

    // Constant Addresses & Parameters

    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint256 constant private MAX_INT = 2**256 - 1;

    // Coin Parameters

    string constant _name = "CARITEST1";
    string constant _symbol = "CARITEST1";
    uint8 constant _decimals = 18;
    address public owner;

    uint256 _totalSupply = 500000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 10;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    uint256 liquidityFee = 150;
    uint256 buybackFee = 150;
    uint256 reflectionFee = 200;
    uint256 charityFee = 150;
    uint256 marketingFee = 50;
    uint256 totalFee = 700;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public charityVaultAddress;

    uint256 targetLiquidity = 70;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackPermille = 100;
    uint256 autoBuybackAmount = address(pair).balance * (autoBuybackPermille / 5000); // pair balance counts twice so 10000 -> 5000
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    PreSale preSales;
    UserManagement userManagement;
    CharityVault charityVault;

    uint256 distributorGas = 500000;
    uint256 feesGas = 70000;

    bool public swapEnabled = false;
    uint256 public swapThresholdPerbillion = 1000;                                  // Swap threshold in %
    uint256 public swapThreshold = 5000000000 * (10 ** _decimals) * swapThresholdPerbillion;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    // Initialize Parameters

    constructor () {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint128).max;

        owner = msg.sender;

        distributor = new DividendDistributor(address(router));
        userManagement = new UserManagement(msg.sender, address(this));
        charityVault = new CharityVault();
        preSales = new PreSale(address(this), WBNB, pair, address(router), address(userManagement));
    

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isFeeExempt[charityVaultAddress] = true;
        isTxLimitExempt[charityVaultAddress] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = address(DEAD);
        marketingFeeReceiver = 0xF53c251ACbfc7Df58A2f47F063af69A3ED897042;
        charityVaultAddress = address(charityVault);

        uint preSalesBalance = _totalSupply / 10 * 7;
        uint contractBalance = _totalSupply / 10 * 3;
        _balances[msg.sender] = contractBalance;
        _balances[address(preSales)] = preSalesBalance;
        emit Transfer(address(0), msg.sender, contractBalance);
        emit Transfer(address(0), address(preSales), preSalesBalance);
    }

    // Initialize Interfaces

    IPreSale iPreSaleConfig = IPreSale(address(preSales));
    IUserManagement iUserManagement = IUserManagement(address(userManagement));

    // Modifiers
    
    modifier authorized() {
        require(iUserManagement.isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    // User Functions

    function charityBuyForLiquidity() public payable {     
        require(address(msg.sender).balance >= msg.value);

        uint256 buyAmount = msg.value; 

        payable (address(preSales)).call{value: msg.value, gas: feesGas};
        iPreSaleConfig.externalCharityBuyForLiquidity(msg.sender, buyAmount);
    }

    // Internal Utility Functions

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp){ return getMultipliedFee(); }
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBCharity = amountBNB.mul(charityFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: feesGas};
        payable(charityVaultAddress).call{value: amountBNBCharity, gas: feesGas};


        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    // SwapBack & BuyBack Admin Settings
    
    function setSwapBackSettings(bool _enabled, uint256 _PerBillion) external authorized {
        swapEnabled = _enabled;
        swapThresholdPerbillion = _PerBillion;
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _Permille, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackPermille = _Permille;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }
        
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }
    
    function triggerLoveBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    // Fees Admin Settings
    
    function setFeesGas(uint256 _newFeesGas) external authorized {
        feesGas = _newFeesGas;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _charityVaultAddress) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        charityVaultAddress = _charityVaultAddress;
    }
    
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _charityFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        charityFee = _charityFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee).add(_charityFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    // Distributor Admin Settings

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    // General Admin Settings Functions

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    // View Functions

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    // Override IBEP...... why ????

    receive() external payable {}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint128).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint128).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Events

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}