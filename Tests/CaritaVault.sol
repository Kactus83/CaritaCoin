pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

import "./IERC20.sol";

contract CharityVault {

    address public creator;
    address public owner;
    uint256 public unlockDate;
    uint256 public createdAt;
    address public caritasWallet = 0xF53c251ACbfc7Df58A2f47F063af69A3ED897042;
    address payable caritasWalletP = payable(caritasWallet);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function CharityLock(
        address _creator,
        address _owner,
        uint256 _unlockDate
    ) public onlyOwner {
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
    }

    // keep all the ether sent to this address
    receive() payable external { 
        emit Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(block.timestamp >= unlockDate);
       //now send all the balance
       caritasWalletP.transfer(address(this).balance);
       emit Withdrew(caritasWalletP, address(this).balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(block.timestamp >= unlockDate);
       IERC20 token = IERC20(_tokenContract);
       //now send all the token balance
       uint256 tokenBalance = token.balanceOf(address(this));
       token.transfer(owner, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    

    function info() public view returns(address, address, uint256, uint256, uint256) {
        return (creator, owner, unlockDate, createdAt, address(this).balance);
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}
