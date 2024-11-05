pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

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

    constructor(uint256 initialSupply, address initialFeeCollector) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        feeCollector = initialFeeCollector;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier notLocked(address from, uint256 value) {
        require(block.timestamp >= lockedUntil[from], "Tokens are locked");
        require(balanceOf[from] >= value, "Insufficient balance");
        _;
    }

    function transfer(address to, uint256 value) public whenNotPaused notLocked(msg.sender, value) returns (bool success) {
        require(to != address(0), "Invalid address");

        uint256 fee = value.mul(transactionFee).div(100);
        uint256 amountToTransfer = value.sub(fee);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(amountToTransfer);
        balanceOf[feeCollector] = balanceOf[feeCollector].add(fee);

        emit Transfer(msg.sender, to, amountToTransfer);
        emit Transfer(msg.sender, feeCollector, fee);
        return true;
    }

    function mint(uint256 value) public onlyOwner {
        uint256 amount = value * (10 ** uint256(decimals));
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Mint(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 value) public notLocked(msg.sender, value) {
        uint256 amount = value * (10 ** uint256(decimals));
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to burn");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function lockTokens(uint256 value, uint256 time) public notLocked(msg.sender, value) {
        uint256 amount = value * (10 ** uint256(decimals));
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to lock");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        lockedUntil[msg.sender] = block.timestamp.add(time);
        emit Lock(msg.sender, amount, lockedUntil[msg.sender]);
    }

    function setFeeCollector(address newFeeCollector) public onlyOwner {
        require(newFeeCollector != address(0), "Invalid address");
        emit FeeCollectorChanged(feeCollector, newFeeCollector);
        feeCollector = newFeeCollector;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        super.transferOwnership(newOwner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}