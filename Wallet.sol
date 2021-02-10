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
    uint256 private dailyLimit;                             // change effect only after 24 hours
    uint256 private dailySpend;                             // spend daily limit each 24 hours
    address[] private whitelist;
    address[] private guardians;
    uint256 private lastWithdrawal = 0;
    mapping (address => uint256) private guardiansEffect;   // [guardian, timeOfAddition] add or delete effect only after 24 hours
    mapping (address => uint256) private whitelistEffect;   // [account, timeOfAddition] add or delete effect only after 24 hours

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

    function transfer(address payable _to, uint256 _amount) payable external ownerOnly {
        require(_amount > 0 && _to != address(0), "Transfer: Input Error");
        if (isWhitelisted(_to) == false) {
            if  (1 days + lastWithdrawal >= block.timestamp) {
                require (dailyLimit >= _amount, "Transfer: Exceeds daily limit !");
                dailySpend = dailyLimit - _amount;
            }
            else {
                require (dailySpend >= _amount, "Transfer: Daily limit reached !");
                dailySpend -= _amount;
            }
            lastWithdrawal = block.timestamp;
        }
        else {                              
            require (iswhitelistEffect(_to) == true, "Transfer: still in whitelistEffect !");
        }
        _to.transfer(_amount);
    }
    
    function getGuardians() view external returns(address[] memory) {
        return (guardians);
    }
    
    function addGuardian(address _guardian) external ownerOnly {
        require(isGuardian(_guardian) == false, "Add Guardian: Already guardian");
        guardians.push(_guardian);
        guardiansEffect[_guardian] = block.timestamp;
    }
    
    function deleteGuardian(address _guardian) external ownerOnly {
        for(uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _guardian) {
                delete guardians[i];
                break;
            }
        }
    }
    
    function isGuardian(address _guardian) view internal returns (bool) {
        for(uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _guardian) {
                return true;
            }
        }
        return false;
    }
    function isGuardianEffect(address _guardian) external returns (bool) {
        if (1 days + guardiansEffect[_guardian] >= block.timestamp) {
            delete guardiansEffect[_guardian];
            return true;
        }
        return false;
    }
    
    function getWhitelist() view external returns(address[] memory) {
        return (whitelist);
    }
    
    function addToWhitelist(address _account) external ownerOnly {
        require(isWhitelisted(_account) == false, "Add White List: Already whitelised !");
        whitelist.push(_account);
        whitelistEffect[_account] = block.timestamp;
    }

    function deleteFromWhitelist(address _account) external ownerOnly {
        for(uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _account) {
                delete whitelist[i];
                break;
            }
        }
    }
    
    function isWhitelisted(address _account) view internal returns (bool) {
        for(uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _account) {
               return true;
            }
        }
        return false;
    }
    
    function iswhitelistEffect(address _account) internal returns (bool) {
        if (1 days + whitelistEffect[_account] >= block.timestamp) {
            delete whitelistEffect[_account];
            return true;
        }
        return false;
    }

    function setDailyLimit(uint256 _limit) external ownerOnly {
        dailyLimit = _limit;
        dailySpend = _limit;
    }

    function getDailyLimit() external view returns (uint256) {
        return dailyLimit;
    }

     function getDailySpend() external view returns (uint256) {
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
