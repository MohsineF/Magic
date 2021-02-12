// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/*
    Wallet vault
    Social recovery
    White list
    Cold storage
*/

contract Wallet {
    enum Type {
        White,
        Guardian
    }
    enum Action {
        Deletion,
        Addition
    }
    struct List {
        address account;
        uint256 time;
        Action action;
        Type group;
    }
    address payable owner;
    uint256 private dailyLimit;                             // change effect only after 24 hours
    uint256 private dailySpend;                             // spend daily limit each 24 hours
    uint256 private lastWithdrawal;
    address[] private whites;
    address[] private guardians;
    List[] private waitList;

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
        if (isWhite(_to) == false) {
            if  (1 days + lastWithdrawal <= block.timestamp) {
                require (dailyLimit >= _amount, "Transfer: Exceeds daily limit !");
                dailySpend = dailyLimit - _amount;
            }
            else {
                require (dailySpend >= _amount, "Transfer: Daily limit reached !");
                dailySpend -= _amount;
            }
            lastWithdrawal = block.timestamp;
        }
        _to.transfer(_amount);
    }
    
    function addGuardian(address _guardian) internal ownerOnly {
        require(isGuardian(_guardian) == false, "Add Guardian: Already guardian");
        guardians.push(_guardian);
    }

    function addWhite(address _account) internal ownerOnly {
        require(isWhite(_account) == false, "Add White: Already whitelisted !");
        whites.push(_account);
    }
    
    function deleteGuardian(address _guardian) internal ownerOnly {
        for(uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _guardian) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
    }
    
    function deleteWhitelist(address _account) internal ownerOnly {
        for(uint256 i = 0; i < whites.length; i++) {
            if (whites[i] == _account) {
                whites[i] = whites[whites.length - 1];
                whites.pop();
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
    
    function isWhite(address _account) view internal returns (bool) {
        for(uint256 i = 0; i < whites.length; i++) {
            if (whites[i] == _account) {
               return true;
            }
        }
        return false;
    }
    
    function addWaitList(address _account, Type _group, Action _action) external {
        require(isGuardian(_account) == false && isWhite(_account) == false, "Wait List: Already added to it's corresponding list");
        waitList.push(List ({
            account: _account,
            time: block.timestamp,
            group: _group,
            action: _action
        }));
    }
    
    function checkWaitList() external returns (bool) {
        for(uint256 i = 0; i < waitList.length; i++) {
            if (1 days + waitList[i].time <= block.timestamp) {
                if (waitList[i].action == Action.Deletion) {
                    if (waitList[i].group == Type.Guardian) deleteGuardian(waitList[i].account);
                    else deleteWhitelist(waitList[i].account);
                }
                else if (waitList[i].action == Action.Addition) {
                    if (waitList[i].group == Type.Guardian) addGuardian(waitList[i].account);
                    else addWhite(waitList[i].account);
                }
                waitList[i] = waitList[waitList.length - 1];
                waitList.pop();
                return false;
            }
        }
        return true;
    }
    
    function getGuardians() view external returns(address[] memory) {
        return (guardians);
    }

    function getWhitelist() view external returns(address[] memory) {
        return (whites);
    }

    function setDailyLimit(uint256 _limit) external ownerOnly {
        dailyLimit = _limit;
        dailySpend = _limit;
    }

    function getDailyLimit() view external returns (uint256) {
        return dailyLimit;
    }

    function getDailySpend() external returns (uint256) {
        if  (1 days + lastWithdrawal <= block.timestamp) {
            dailySpend = dailyLimit;
        }
        return dailySpend;
    }

    function balanceOf() view external returns (uint256) {
        return address(this).balance;
    }

    function ownerOf() view external returns (address) {
        return owner;
    }

    function kill(address payable _account) external ownerOnly {
        selfdestruct(_account);
    }

    receive() external payable {
    }
    
    fallback() external {
    }
}

