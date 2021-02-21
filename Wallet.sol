// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/*
    Wallet vault
    Social recovery
    White list
    Cold storage
*/

import './Whites.sol';
import './Guardians.sol';


contract Wallet is Guardians, Whites {
    struct Limit {
        uint256 dailyLimit;
        uint256 dailySpend;
        uint256 lastWithdrawal;
        uint256 time;
        uint256 newLimit;
    }
    address payable owner;
    Limit private limit;
    Guardians guardians;
    Whites whites;
    
    constructor (address payable _owner) {
        owner = _owner;
    }
     
    modifier ownerOnly() {
        require (msg.sender == owner, "Wallet: Access denied, not an owner !");
        _;
    }
    
    modifier guardianOnly() {
        require (guardians.isGuardian(msg.sender), "Wallet: Access denied, not an owner !");
        _;
    }

    function transfer(address payable _to, uint256 _amount) payable external ownerOnly {
        require(_to != address(0), "Transfer: Null address !");
        if (!whites.isWhite(_to)) {
            if  (block.timestamp >= limit.lastWithdrawal) {
                require (limit.dailyLimit >= _amount, "Transfer: Exceeds daily limit !");
                limit.dailySpend = limit.dailyLimit - _amount;
                limit.lastWithdrawal = block.timestamp + 24 hours;
            }
            else {
                require (limit.dailySpend >= _amount, "Transfer: Daily limit reached !");
                limit.dailySpend -= _amount;
            }
        }
        _to.transfer(_amount);
    }
    
    function recover(uint8[] calldata v, bytes32[] calldata s, bytes32[] calldata r, address payable _owner) override external guardianOnly {
        guardians.recover(v, s, r, _owner);
        owner = _owner;
    }
    
    function addGuardian(address _account) override external ownerOnly {
        guardians.addGuardian(_account);
    }
    
    function addWhite(address _account) override external ownerOnly {
        whites.addWhite(_account);
    }
    
    function addGuardianWaitList(address _account) override external ownerOnly {
        guardians.addGuardianWaitList(_account);
    }
    
    function addWhiteWaitList(address _account) override external ownerOnly {
        whites.addWhiteWaitList(_account);
    }
    
    function addNewDailyLimit(uint256 _limit) external ownerOnly {
        require (_limit > 0, "Limit: Zero not allowed !");
        limit.time = block.timestamp + 30 seconds;
        limit.newLimit = _limit;
    }
    
    function confirmNewDailyLimit() external ownerOnly {
        require (block.timestamp > limit.time, "Daily Limit: Still needs time !");
        limit.dailyLimit = limit.newLimit;
        limit.dailySpend = limit.newLimit;
    }
    
    function getDailyLimit() view external returns (uint256) {
        return limit.dailyLimit;
    }

    function getDailySpend() view external returns (uint256) {
        return limit.dailySpend;
    }

    function getBalance() view external returns (uint256) {
        return address(this).balance;
    }

    function ownerOf() view external returns (address) {
        return owner;
    }

    function kill(address payable _account) internal ownerOnly {
        require (address(this).balance == 0, "Kill: Still positive balance !");
        selfdestruct(_account);
    }

    receive() external payable {
    }

    fallback() external payable {
    }
}

