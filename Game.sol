// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract ERC1155 {
    struct token {
        uint256 _token;    
        string _name;
        string _symbol;
    }
    mapping (uint256 => address) private _tokenOwner;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

}

contract ERC721 {
    uint256 private _token;    
    string private _name;
    string private _symbol;
    mapping (uint256 => address) private _tokenOwner;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721: Null address");
        return _ownedTokensCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenOwner[_tokenId] != address(0), "ERC721: Null address");
        return _tokenOwner[_tokenId];
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(_to != address(0), "ERC721: Null address");
        require(msg.sender == _tokenOwner[_tokenId] || msg.sender == _tokenApprovals[_tokenId]  || _operatorApprovals[_from][msg.sender], "ERC721: Not allowed");
        delete _tokenApprovals[_tokenId];
        _tokenOwner[_tokenId] = _to;
        _ownedTokensCount[_from] -= 1;
        _ownedTokensCount[_to] += 1;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        transferFrom(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external payable {
        require(_approved != address(0), "ERC721: Null address");
        require(msg.sender == _tokenOwner[_tokenId] || _operatorApprovals[_approved][msg.sender], "ERC721: not allowed");
        
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_tokenOwner[_tokenId], _approved, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenOwner[_tokenId] != address(0), "ERC721: not  valid token");
        return _tokenApprovals[_tokenId];
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }
}

contract ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address sender, address recipient, uint256 value);
    event Approve(address sender, address recipient, uint256 value);

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function balanceOf(address account) public view returns (uint256 balance) {
        return _balances[account];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value, "Not enough in balance!");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance(_from, _to) >= _value, "Not allowed!");
        require(_balances[_from] >= _value, "Not enough in balance!");
        _balances[_from] -= _value;
        _balances[_from] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
}
