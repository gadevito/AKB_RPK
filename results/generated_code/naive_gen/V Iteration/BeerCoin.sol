// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract BeerCoin is Ownable, Pausable {
    string public name = "BeerCoin";
    string public symbol = "BEER";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public feeCollector;
    uint256 public transactionFee = 1; // 1% fee

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public lockTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Lock(address indexed owner, uint256 value, uint256 releaseTime);

    constructor(uint256 _initialSupply, address _feeCollector) {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        feeCollector = _feeCollector;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier notLocked(address _from, uint256 _value) {
        require(block.timestamp >= lockTime[_from], "Tokens are locked");
        _;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notLocked(msg.sender, _value) returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");

        uint256 fee = (_value * transactionFee) / 100;
        uint256 amountToTransfer = _value - fee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amountToTransfer;
        balanceOf[feeCollector] += fee;

        emit Transfer(msg.sender, _to, amountToTransfer);
        emit Transfer(msg.sender, feeCollector, fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notLocked(_from, _value) returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");

        uint256 fee = (_value * transactionFee) / 100;
        uint256 amountToTransfer = _value - fee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += amountToTransfer;
        balanceOf[feeCollector] += fee;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, amountToTransfer);
        emit Transfer(_from, feeCollector, fee);
        return true;
    }

    function mint(uint256 _amount) public onlyOwner {
        uint256 amount = _amount * 10 ** uint256(decimals);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Mint(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 _amount) public {
        uint256 amount = _amount * 10 ** uint256(decimals);
        require(amount <= balanceOf[msg.sender], "Insufficient balance to burn");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function lockTokens(uint256 _time) public {
        lockTime[msg.sender] = block.timestamp + _time;
        emit Lock(msg.sender, balanceOf[msg.sender], lockTime[msg.sender]);
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

    function transferOwnership(address newOwner) public override onlyOwner {
        transferOwnership(newOwner);
    }
}