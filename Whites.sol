// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Whites {
    address[] private whites;
    mapping (address => uint256) whiteWaitList;
   
    function setWhites(address[] memory _whites) virtual external {
        for(uint8 i = 0; i < _whites.length; i++) {
            whites.push(_whites[i]);
        }
    }

    function addWhiteWaitList(address _account) virtual external {
        require (!isWhite(_account), "Wait List: Already a white !");
        require (whiteWaitList[_account] == 0, "Wait List: Already in wait list !");
        whiteWaitList[_account] = block.timestamp + 30 seconds;
    }
    
    function deleteWhiteWaitList(address _account) virtual external {
        delete whiteWaitList[_account];
    }
    
    function addWhite(address _account) virtual external {
        require (whiteWaitList[_account] != 0, "Add White: Not in wait list !");
        require (block.timestamp > whiteWaitList[_account], "Add White: Still needs time !");
        whites.push(_account);
        delete whiteWaitList[_account];
    }
    
    function deleteWhite(address _account) virtual external {
        require (whiteWaitList[_account] != 0, "Delete White: Not in wait list !");
        require (block.timestamp > whiteWaitList[_account], "Delete White: Still needs time !");
        for(uint16 i = 0; i < whites.length; i++) {
            if (whites[i] == _account) {
                whites[i] = whites[whites.length - 1];
                whites.pop();
                break;
            }
        }
    }
    
    function getWhites() view external returns (address[] memory) {
        return (whites);
    }
    
    function isWhite(address _account) view public returns (bool) {
        for(uint8 i = 0; i < whites.length; i++) {
            if (whites[i] == _account) {
                return true;
            }
        }
        return false;
    }
}

