// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeerCoin {
    string public name = "BeerCoin";
    string public symbol = "BEER";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public transactionFee = 5;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockedUntil;
    address public owner;
    address public feeCollector;


    bool public paused = false;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor(uint256 initialSupply, address _feeCollector) {
        owner = msg.sender;
        feeCollector = _feeCollector;
        mint(owner, initialSupply);
    }

    function mint(address to, uint256 value) public onlyOwner {
        totalSupply += value;
        balances[to] += value;
    }

    function burn(uint256 value) public {
        require(balances[msg.sender] >= value, "Insufficient balance");
        totalSupply -= value;
        balances[msg.sender] -= value;
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(block.timestamp >= lockedUntil[msg.sender], "Tokens are locked");

        uint256 fee = (value * transactionFee) / 100;
        uint256 netValue = value - fee;

        balances[msg.sender] -= value;
        balances[to] += netValue;
        balances[feeCollector] += fee;

        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function lockTokens(uint256 time) public {
        lockedUntil[msg.sender] = block.timestamp + time;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function setTransactionFee(uint256 newFee) public onlyOwner {
        require(newFee <= 100, "Fee cannot exceed 100%");
        transactionFee = newFee;
    }

    function setFeeCollector(address newCollector) public onlyOwner {
        require(newCollector != address(0), "New fee collector is the zero address");
        feeCollector = newCollector;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}
