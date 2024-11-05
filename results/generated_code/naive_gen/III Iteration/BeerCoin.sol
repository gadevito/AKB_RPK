// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BeerCoin is Ownable, Pausable {
    using SafeMath for uint256;

    string public constant name = "BeerCoin";
    string public constant symbol = "BEER";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public feeCollector;
    uint256 public transactionFee = 1; // 1% fee

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => uint256) private lockTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Lock(address indexed from, uint256 value, uint256 releaseTime);

    constructor(uint256 initialSupply, address _feeCollector) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        feeCollector = _feeCollector;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier notLocked(address _from, uint256 _value) {
        require(block.timestamp >= lockTime[_from], "Tokens are locked");
        _;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notLocked(msg.sender, _value) returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        uint256 fee = _value.mul(transactionFee).div(100);
        uint256 amountToTransfer = _value.sub(fee);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(amountToTransfer);
        balances[feeCollector] = balances[feeCollector].add(fee);

        emit Transfer(msg.sender, _to, amountToTransfer);
        emit Transfer(msg.sender, feeCollector, fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notLocked(_from, _value) returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Allowance exceeded");

        uint256 fee = _value.mul(transactionFee).div(100);
        uint256 amountToTransfer = _value.sub(fee);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(amountToTransfer);
        balances[feeCollector] = balances[feeCollector].add(fee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, amountToTransfer);
        emit Transfer(_from, feeCollector, fee);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint(uint256 _amount) public onlyOwner {
        totalSupply = totalSupply.add(_amount);
        balances[owner()] = balances[owner()].add(_amount);
        emit Mint(owner(), _amount);
        emit Transfer(address(0), owner(), _amount);
    }

    function burn(uint256 _amount) public {
        require(_amount <= balances[msg.sender], "Insufficient balance to burn");
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function lockTokens(uint256 _amount, uint256 _time) public {
        require(_amount <= balances[msg.sender], "Insufficient balance to lock");
        lockTime[msg.sender] = block.timestamp.add(_time);
        emit Lock(msg.sender, _amount, lockTime[msg.sender]);
    }

    function setFeeCollector(address _feeCollector) public onlyOwner {
        feeCollector = _feeCollector;
    }

    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        transactionFee = _transactionFee;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}