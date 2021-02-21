pragma solidity >=0.7.0 <0.8.0;

contract Wallet {
    struct Limit {
        uint256 dailyLimit;
        uint256 dailySpend;
        uint256 lastWithdrawal;
        uint256 time;
        uint256 newLimit;
    }
    address payable owner;
    uint256 private recoverID;
    uint256 private lockTime;
    Limit private limit;
    address[] private whites;
    address[] private guardians;
    mapping (address => mapping(bool => uint256)) waitList;

    event Transter(address _to, uint256 _amount);
    event Recover(address _account);

    constructor (address payable _owner, uint256 _dailyLimit, address[] memory _whites, address[] memory _guardians) {
        owner = _owner;
        limit.dailyLimit = _dailyLimit;
        limit.dailySpend = _dailyLimit;
        whites = _whites;
        guardians = _guardians;
    }
     
    modifier ownerOnly() {
        require (msg.sender == owner, "Wallett: Access denied, not an owner !");
        _;
    }
    
    modifier guardiansOnly() {
        require (isIn(guardians, msg.sender), "Wallet: Access denied, not a guardian !");
        _;
    }
    
    modifier notLocked() {
        require (block.timestamp > lockTime, "Wallet: wallet is locked !");
        _;
    }

    function transfer(address payable _to, uint256 _amount) payable external ownerOnly notLocked {
        require(_to != address(0), "Transfer: Null address !");
        if (!isIn(whites, _to)) {
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

    function recover(uint8[] calldata v, bytes32[] calldata s, bytes32[] calldata r, address payable _owner) external ownerOnly {
        require (isIn(guardians, _owner) == false, "Recover: New owner cannot be a guardian !");
        address[] memory recoveryList = new address[](v.length - 1);
        bytes32 hash = keccak256(abi.encodePacked(recoverID, _owner, address(this)));

        for (uint8 i = 0; i < s.length; i++) {
            recoveryList[i] = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v[i], r[i], s[i]);
            require (!isIn(recoveryList, recoveryList[i]) && isIn(guardians, recoveryList[i]), "Recover: Recovery error !");
        }
        require (recoveryList.length > (guardians.length / 2) + 1, "Recover: Not enough guardians signatures");
        owner = _owner;
        recoverID++;
    }
    
    function lock() external guardiansOnly notLocked {
        lockTime = block.timestamp + 5 days;
    }
    
    function unlock() external guardiansOnly {
        lockTime = 0;
    }
    
    function addToWaitList(address _account, bool _group) external ownerOnly {
        require (waitList[_account][_group] == 0, "Wait List: Already in wait list !");
        waitList[_account][_group] = block.timestamp + 30 seconds;
    }
    
    function deleteFromWaitList(address _account, bool _group) external ownerOnly {
        delete waitList[_account][_group];
    }
    
    function addGuardian(address _account) external ownerOnly {
        require (!isIn(guardians, _account), "Add Guardian: Already a guardian !");
        require (waitList[_account][true] != 0, "Add Guardian: Not in wait list !");
        require (block.timestamp > waitList[_account][true], "Add Guardian: Still needs time !");
        guardians.push(_account);
        delete waitList[_account][true];
    }
    
    function addWhite(address _account) external ownerOnly {
        require (!isIn(whites, _account), "Add White: Already a white !");
        require (waitList[_account][false] != 0, "Add White: Not in wait list !");
        require (block.timestamp > waitList[_account][false], "Add White: Still needs time !");
        whites.push(_account);
        delete waitList[_account][false];
    }
    
    function deleteGuardian(address _account) external ownerOnly {
        require (isIn(guardians, _account), "Delete Guardian: Not a guardian !");
        require (block.timestamp > waitList[_account][true], "Delete Guardian: Still needs time !");
        for(uint8 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _account) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
        delete waitList[_account][true];
    }

    function deleteWhite(address _account) external ownerOnly {
        require (isIn(whites, _account), "Delete White: Not a white !");
        require (block.timestamp > waitList[_account][false], "Delete White: Still needs time !");
        for(uint16 i = 0; i < whites.length; i++) {
            if (whites[i] == _account) {
                whites[i] = whites[whites.length - 1];
                whites.pop();
                break;
            }
        }
        delete waitList[_account][false];
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

    function isIn(address[] memory _array, address _account) pure internal returns (bool) {
        for(uint8 i = 0; i < _array.length; i++) {
            if (_array[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function getGuardians() view external returns (address[] memory) {
        return (guardians);
    }

    function getWhitelist() view external returns (address[] memory) {
        return (whites);
    }
    
    function getDailyLimit() view external returns (uint256) {
        return limit.dailyLimit;
    }

    function getDailySpend() view external returns (uint256) {
        return limit.dailySpend;
    }
    
    function getRecoverId() view external returns (uint256) {
        return (recoverID);
    }
    
    function balanceOf() view external returns (uint256) {
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
