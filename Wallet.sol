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
    uint256 private balance;
    uint256 private dailyLimit;
    uint256 private dailySpend;
    uint256 private lastWithdrawal;
    uint256 private nounce;
    mapping (address => bool) private whiteList;

    constructor (address payable _owner_) {
        owner = _owner_;
    }
    
    modifier ownerOnly() {
        require (msg.sender == owner, "Wallet: Access denied !");
        _;
    }
    
    function transfer(address _to, uint256 _amount) payable external ownerOnly {
        require(_amount > 0 && _to != address(0));
        if (whiteList[_to] != true) {
            if  (lastWithdrawal + 1 days >= block.timestamp) {
                require (dailyLimit >= _amount, "Transfer: Daily limit reached !");
                dailySpend = dailyLimit - _amount;
                lastWithdrawal = block.timestamp;
                owner.transfer(_amount);
            }
            else {
                require (dailySpend >= _amount, "Transfer: Daily limit reached !");
                dailySpend -= _amount;
                owner.transfer(_amount);
            }
        }
        else {
            // whitelisted
            owner.transfer(_amount);
        }
    }
    
    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }
    
    function ownerOf() external view returns (address) {
        return owner;
    }
    
    function setDailyLimit(uint256 _limit) external ownerOnly {
        dailyLimit = _limit;
        dailySpend = _limit;
    }
    
    function getDailyLimit() external view ownerOnly returns (uint256){
        return dailyLimit;
    }
    
     function getDailySpend() external view ownerOnly returns (uint256){
        return dailySpend;
    }
    
    
    function addWhiteList(address _account) external ownerOnly {
        require(whiteList[_account] == false, "Add White List: Already exists !");
        whiteList[_account] = true;
    }
    
    function deleteWhiteList(address _account) external ownerOnly {
        require(whiteList[_account] == true, "Delete white List: Not in white list !");
        delete whiteList[_account];
    }
    
    function kill() external ownerOnly{
        selfdestruct(owner);
    }
    
    receive() external payable {
        balance = msg.value;
    }
}
