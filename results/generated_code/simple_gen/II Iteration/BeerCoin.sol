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
    mapping(address => uint256) public lockedUntil;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Lock(address indexed from, uint256 value, uint256 releaseTime);
    event FeeCollectorChanged(address indexed previousCollector, address indexed newCollector);
    event TransactionFeeChanged(uint256 previousFee, uint256 newFee);

    constructor(uint256 _initialSupply, address _feeCollector) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        feeCollector = _feeCollector;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier notLocked(address _from, uint256 _value) {
        require(block.timestamp >= lockedUntil[_from], "Tokens are locked");
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

    function mint(uint256 _amount) public onlyOwner {
        uint256 amount = _amount * (10 ** uint256(decimals));
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Mint(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 _amount) public notLocked(msg.sender, _amount) {
        uint256 amount = _amount * (10 ** uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function lockTokens(uint256 _amount, uint256 _time) public notLocked(msg.sender, _amount) {
        uint256 amount = _amount * (10 ** uint256(decimals));
        lockedUntil[msg.sender] = block.timestamp.add(_time);
        emit Lock(msg.sender, amount, lockedUntil[msg.sender]);
    }

    function setFeeCollector(address _newCollector) public onlyOwner {
        require(_newCollector != address(0), "Invalid address");
        emit FeeCollectorChanged(feeCollector, _newCollector);
        feeCollector = _newCollector;
    }

    function setTransactionFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 100, "Fee too high");
        emit TransactionFeeChanged(transactionFee, _newFee);
        transactionFee = _newFee;
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