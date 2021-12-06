// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface IPreSale {


    function charityBuyForLiquidity(address _sender, uint _amount) external;

    function endSale(address _sender) external;

    function changeToken (address _newTokenAddress, address _newPairAddress) external;

    function changeRouter (address _newRouterAddress) external;
 
    function getEstimatedTokenForBNB(uint buyAmountInWei) external view returns (uint[] memory bnbQuote);
}
