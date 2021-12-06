// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


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
