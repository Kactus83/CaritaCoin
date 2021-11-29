pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


interface IERC20Token {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

interface IPancakeRouter01 {
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
        
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
}

contract caritasFirstSale {

    IERC20Token public tokenContract = IERC20Token(tokenAddress);  // the token being sold
    uint256 public price = 100000;              // the price, in wei, per token

    address owner;
    address public tokenAddress = 0xfa5Eb8849845ba528B73D2AB07594Ea75DCc4130;
    uint256 public tokensSold;
    uint256 private tokenForLiquidity;
    uint256 private bnbForLiquidity;
    address private routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    event Sold(address buyer, uint256 amount);

    function TokenSale(IERC20Token _tokenContract, uint256 _price) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }

    function adjustPrice( uint256 _newPrice) public {
        require(msg.sender == owner);
        price = _newPrice;
    }

    function buyPublicLiquidity (uint tokenAmountToSell) private {

        IPancakeRouter02 pancakeRouter = IPancakeRouter02 (routerAddress);

        pancakeRouter.addLiquidityETH(
        tokenAddress,
        tokenAmountToSell,
        0,
        0,
        address(this),
        block.timestamp + 360
        );
    }

    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }
    

    function charityBuyForLiquidity(uint256 numberOfTokens) public payable {
        require(msg.value == safeMultiply(numberOfTokens, price));

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(address(this)) >= scaledAmount);

        emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount));
        
        buyPublicLiquidity(tokenForLiquidity);
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));

        payable(msg.sender).transfer(address(this).balance);
    }

    function setRouterAddress(address newRouter) public {
        require(msg.sender == owner);
        routerAddress = newRouter;
    }
}
