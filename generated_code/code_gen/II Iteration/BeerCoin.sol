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
    uint256 public transactionFee;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockedTokens;
    mapping(address => uint256) public lockExpiry;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Paused();
    event Unpaused();
    event FeeCollectorChanged(address indexed previousCollector, address indexed newCollector);
    event TokensLocked(address indexed account, uint256 amount, uint256 expiry);

    constructor(uint256 _initialSupply, address _feeCollector) {
        transferOwnership(msg.sender);
        totalSupply = _initialSupply;
        balances[owner()] = _initialSupply;
        feeCollector = _feeCollector;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to the zero address");
        require(amount > 0, "Mint amount must be greater than zero");

        totalSupply = totalSupply + amount;

        uint256 currentBalance = balances[to];
        balances[to] = currentBalance + amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 _amount) public {
        // Check if the caller has enough balance to burn the specified amount of tokens
        require(balances[msg.sender] >= _amount, "Insufficient balance to burn");

        // Subtract the _amount from the caller's balance
        balances[msg.sender] = balances[msg.sender] - _amount;

        // Decrease the totalSupply by the _amount
        totalSupply = totalSupply - _amount;

        // Emit the Burn event with the caller's address and the _amount burned
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_to != address(0), "Transfer to the zero address");

        uint256 senderBalance = balances[msg.sender];
        uint256 lockedAmount = lockedTokens[msg.sender];
        uint256 lockExpiryTime = lockExpiry[msg.sender];
        uint256 fee = transactionFee;

        require(senderBalance >= _value + fee, "Insufficient balance");
        require(block.timestamp >= lockExpiryTime || senderBalance - lockedAmount >= _value + fee, "Tokens are locked");

        balances[msg.sender] = senderBalance - _value - fee;
        balances[_to] += _value;

        balances[feeCollector] += fee;

        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, feeCollector, fee);

        return true;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function lockTokens(uint256 _amount, uint256 _lockPeriod) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_lockPeriod > 0, "Lock period must be greater than zero");

        uint256 userBalance = balances[msg.sender];
        require(userBalance >= _amount, "Insufficient balance to lock tokens");

        uint256 currentLockedTokens = lockedTokens[msg.sender];
        uint256 newLockedTokens = currentLockedTokens + _amount;
        lockedTokens[msg.sender] = newLockedTokens;

        uint256 newLockExpiry = block.timestamp + _lockPeriod;
        lockExpiry[msg.sender] = newLockExpiry;

        emit TokensLocked(msg.sender, _amount, newLockExpiry);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");

        address currentOwner = owner();
        super.transferOwnership(newOwner);

        emit OwnershipTransferred(currentOwner, newOwner);
    }

    function setFeeCollector(address _newFeeCollector) public onlyOwner {
        require(_newFeeCollector != address(0), "New fee collector address cannot be zero address");

        address previousCollector = feeCollector;
        feeCollector = _newFeeCollector;

        emit FeeCollectorChanged(previousCollector, _newFeeCollector);
    }
}