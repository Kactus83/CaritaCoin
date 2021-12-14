pragma solidity >=0.8.9;
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


import "./Libraries/SafeMath.sol";

import "./Interfaces/IDEXFactory+IDEXRouter.sol";
import "./Interfaces/IBEP20.sol";
import "./Interfaces/IPreSale.sol";
import "./Interfaces/ICharityVault.sol";
import "./Interfaces/IUserManagement.sol";
import "./Interfaces/ICoin.sol";

import "./UserManagement.sol";
import "./PreSale.sol";
import "./DividendDistributor.sol";
import "./CharityVault.sol";


contract CaritaCoinLight is IBEP20, ContextSlave {
    using SafeMath for uint256;

    // Coin Parameters

    string constant _name = "CARITEST1";
    string constant _symbol = "CARITEST1";
    uint8 constant _decimals = 18;

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

    uint256 targetLiquidity = 70;
    uint256 targetLiquidityDenominator = 100;


    uint256 public launchedAt;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackPermille = 100;
    uint256 autoBuybackAmount = address(dexPair).balance * (autoBuybackPermille / 5000); // dexPair balance counts twice so 10000 -> 5000
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;

    uint256 distributorGas = 500000;
    uint256 feesGas = 70000;

    bool public swapEnabled = false;
    uint256 public swapThresholdPerbillion = 1000;                                  // Swap threshold in %
    uint256 public swapThreshold = 5000000000 * (10 ** _decimals) * swapThresholdPerbillion;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }


    // Events

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);

    // Initialize Parameters

    constructor () {

        owner = msg.sender;

        _allowances[address(this)][address(iRouter)] = type(uint128).max;
       
        // Create Contracts

        distributor = new DividendDistributor(ROUTER);
        CharityVault charityVault = new CharityVault();
        PreSale preSales = new PreSale();
        distributorAddress = address(distributor);
        charityVaultAddress = address(charityVault);
        preSalesAddress = address(preSales);

        // Set Interfaces

        iPreSaleConfig = IPreSale(address(preSalesAddress));
        iCharityVault = ICharityVault(charityVaultAddress);
        
        // Create Pair and Set Router

        iRouter = IDEXRouter(ROUTER);
        dexPair = IDEXFactory(iRouter.factory()).createPair(WBNB, address(this));

        // Set Up UserManagement

        UserManagement userManagement = new UserManagement();
        userManagementAddress = address(userManagement);
        iUserManagement = IUserManagement(userManagementAddress);
        iPreSaleConfig.setUserManagementAddress(userManagementAddress);
        iCharityVault.setUserManagementAddress(userManagementAddress);
        iUserManagement.initialVariableEdition(dexPair, charityVaultAddress, preSalesAddress, distributorAddress);

        // Fees Settings 

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isFeeExempt[charityVaultAddress] = true;
        isTxLimitExempt[charityVaultAddress] = true;
        isDividendExempt[dexPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = DEVWALLET;
        charityVaultAddress = address(charityVaultAddress);

        uint preSalesBalance = _totalSupply / 10 * 7;
        uint contractBalance = _totalSupply / 10 * 3;
        _balances[msg.sender] = contractBalance;
        _balances[address(preSalesAddress)] = preSalesBalance;
        emit Transfer(address(0), msg.sender, contractBalance);
        emit Transfer(address(0), address(preSalesAddress), preSalesBalance);
    }

    // Modifiers
    
    modifier authorized() {
        require(iUserManagement.isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    // User Functions

    function charityBuyForLiquidity() public payable {     
        require(address(msg.sender).balance >= msg.value);

        uint256 buyAmount = msg.value; 

        payable (address(preSalesAddress)).call{value: msg.value, gas: feesGas};
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
        uint256 feeAmount = amount.mul(getTotalFee(receiver == dexPair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != dexPair
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

        iRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
            iRouter.addLiquidityETH{value: amountBNBLiquidity}(
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
        return msg.sender != dexPair
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

        iRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
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
        require(holder != address(this) && holder != dexPair);
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
        return accuracy.mul(balanceOf(dexPair).mul(2)).div(getCirculatingSupply());
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

        if(!launched() && recipient == dexPair){ require(_balances[sender] > 0); launch(); }

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
}