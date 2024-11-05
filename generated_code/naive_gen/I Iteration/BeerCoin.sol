// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BeerCoin is Ownable, Pausable {
    using SafeMath for uint256;

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
    event Lock(address indexed from, uint256 lockTime);

    constructor(uint256 initialSupply, address _feeCollector) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        feeCollector = _feeCollector;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier notLocked(address _from, uint256 _value) {
        require(block.timestamp > lockTime[_from], "Tokens are locked");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        _;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notLocked(msg.sender, _value) returns (bool success) {
        require(_to != address(0), "Invalid address");
        uint256 fee = _value.mul(transactionFee).div(100);
        uint256 amountToTransfer = _value.sub(fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(amountToTransfer);
        balanceOf[feeCollector] = balanceOf[feeCollector].add(fee);
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
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        uint256 fee = _value.mul(transactionFee).div(100);
        uint256 amountToTransfer = _value.sub(fee);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(amountToTransfer);
        balanceOf[feeCollector] = balanceOf[feeCollector].add(fee);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, amountToTransfer);
        emit Transfer(_from, feeCollector, fee);
        return true;
    }

    function mint(uint256 _amount) public onlyOwner {
        uint256 amount = _amount * 10 ** uint256(decimals);
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Mint(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 _amount) public {
        uint256 amount = _amount * 10 ** uint256(decimals);
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function lockTokens(uint256 _time) public {
        lockTime[msg.sender] = block.timestamp.add(_time);
        emit Lock(msg.sender, lockTime[msg.sender]);
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
        Ownable.transferOwnership(newOwner);
    }
}