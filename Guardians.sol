// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Guardians {
    address[] private guardians;
    uint256 private recoverID;
    mapping (address => uint256) guardianWaitList;

    function recover(uint8[] calldata v, bytes32[] calldata s, bytes32[] calldata r, address payable _owner) virtual external {
        address[] memory recoveryList = new address[](v.length - 1);
        bytes32 hash = keccak256(abi.encodePacked(recoverID, _owner, address(this)));

        for (uint8 i = 0; i < s.length; i++) {
            recoveryList[i] = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v[i], r[i], s[i]);
            require (!isIn(recoveryList, recoveryList[i]) && isGuardian(recoveryList[i]), "Recover: Recovery error !");
        }
        require (recoveryList.length > (guardians.length / 2) + 1, "Recover: Not enough guardians signatures");
        recoverID++;
    }
    
    function isIn(address[] memory _array, address _account) pure internal returns (bool) {
        for(uint8 i = 0; i < _array.length; i++) {
            if (_array[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function setGuardians(address[] memory _guardians) virtual external {
        for(uint8 i = 0; i < _guardians.length; i++) {
            guardians.push(_guardians[i]);
        }
    }
    
    function addGuardianWaitList(address _account) virtual external {
        require (!isGuardian(_account), "Wait List: Already a guardian !");
        require (guardianWaitList[_account] == 0, "Wait List: Already in wait list !");
        guardianWaitList[_account] = block.timestamp + 30 seconds;
    }
    
    function deleteGuardianWaitList(address _account) virtual external {
        delete guardianWaitList[_account];
    }
    
    function addGuardian(address _account) virtual external {
        require (guardianWaitList[_account] != 0, "Add Guardian: Not in wait list !");
        require (block.timestamp > guardianWaitList[_account], "Add Guardian: Still needs time !");
        guardians.push(_account);
        delete guardianWaitList[_account];
    }
    
    function deleteGuardian(address _account) virtual external {
        require (guardianWaitList[_account] != 0, "Delete Guardian: Not in wait list !");
        require (block.timestamp > guardianWaitList[_account], "Delete Guardian: Still needs time !");
        for(uint8 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _account) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
    }
    
    function getGuardians() view external returns (address[] memory) {
        return (guardians);
    }
    
    function getRecoverId() view external returns (uint256) {
        return (recoverID);
    }
    
    function isGuardian(address _account) view public returns (bool) {
        for(uint8 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _account) {
                return true;
            }
        }
        return false;
    }
}
