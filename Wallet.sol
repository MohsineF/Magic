// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/*
    Wallet vault
    Social recovery
    White list
    Cold storage
*/

contract Wallet {
    address payable owner;
    uint256 private dailyLimit;
    uint256 private dailySpend;
    uint256 private lastWithdrawal;
    address[] private whiteList;
    address[] private guardians; //delay
    uint8 guardiansCount; 
    uint8 whiteListCount;

    constructor (address payable _owner_) {
        owner = _owner_;
    }

    modifier ownerOnly() {
        require (msg.sender == owner, "Wallet: Access denied !");
        _;
    }
    
    modifier guardiansOnly() {
        _;
    }

    function transfer(address _to, uint256 _amount) payable external ownerOnly {
        require(_amount > 0 && _to != address(0));
        if (isWhiteListed(_to) == false) {
            if  (1 days <= block.timestamp - lastWithdrawal) {
                require (dailyLimit >= _amount, "Transfer: Exceeds daily limit !");
                dailySpend = dailyLimit - _amount;
                lastWithdrawal = block.timestamp;
            }
            else {
                require (dailySpend >= _amount, "Transfer: Daily limit reached !");
                dailySpend -= _amount;
            }
        }
        address(this).transfer(_amount);
    }

    function getWhiteList() view external returns(address[] memory) {
        return (whiteList);
    }
    
    function addToWhiteList(address _account) external ownerOnly {
        require(isWhiteListed(_account) == false, "Add White List: Already exists !");
        whiteList[whiteListCount++] = _account;
    }

    function deleteFromWhiteList(address _account) external ownerOnly {
        for(uint256 i = 0; i < whiteListCount; i++) {
            if (whiteList[i] == _account) {
                delete whiteList[i];
                whiteListCount--;
            }
        }
    }
    
    function isWhiteListed(address _account) view internal returns(bool){
        for(uint256 i = 0; i < whiteListCount; i++) {
            if (whiteList[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function setDailyLimit(uint256 _limit) external ownerOnly {
        dailyLimit = _limit;
        dailySpend = _limit;
    }

    function getDailyLimit() external view ownerOnly returns (uint256) {
        return dailyLimit;
    }

     function getDailySpend() external view ownerOnly returns (uint256) {
        return dailySpend;
    }

    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }

    function ownerOf() external view returns (address) {
        return owner;
    }

    function kill() external ownerOnly {
        selfdestruct(owner);
    }

    receive() external payable {
    }

    fallback() external {
    }
}
